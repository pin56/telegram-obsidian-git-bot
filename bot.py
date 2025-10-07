import os

# Set GitPython refresh environment variable to suppress warnings
os.environ['GIT_PYTHON_REFRESH'] = 'quiet'

import logging
from redactor import update_file
from dotenv import load_dotenv
from telegram import InlineKeyboardButton, Update, InlineKeyboardMarkup, ForceReply, ReactionTypeEmoji
from telegram.ext import ApplicationBuilder, CallbackQueryHandler, CommandHandler, ContextTypes, MessageHandler, filters

load_dotenv()

TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
USER_ID = os.getenv('USER_ID')


# Parse user IDs, handling both single ID and comma-separated IDs
if USER_ID:
    users = [int(user_id.strip()) for user_id in USER_ID.replace(',', ' ').split() if user_id.strip()]
else:
    users = []


logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)

logging.getLogger("httpx").setLevel(logging.WARNING)

logger = logging.getLogger(__name__)

async def check_user(user: Update.effective_user):
    if user.id in users:
        return True
    else:
        logger.info(f"User {user.id} is not authorized to use this bot") 
        return False

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /start is issued."""
    user = update.effective_user
    print(users)
    if check_user:
        await update.message.reply_html(
            rf"Hi {user.mention_html()}!",
            reply_markup=ForceReply(selective=True),
        )



async def echo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Echo the user message."""
    user = update.effective_user
    logger.info(f"Received message from user {user.id}, authorized users: {users}")
    
    if check_user(update.effective_user):
        urls = []
        if update.message.caption_entities:
            for i in update.message.caption_entities:
                if i.url:
                    urls.append(i.url)
        print(f"Found URLs: {urls}")
        
        # Extract message text
        if update.message.text is not None:
            message = update.message.text
        else:
            message = update.message.caption
        
        logger.info(f"Processing message: {message}")
        
        # Extract author information
        if update.message.forward_origin is not None:
            # This is a forwarded message
            if hasattr(update.message.forward_origin, 'sender_user'):
                # Forwarded from a user
                autor = update.message.forward_origin.sender_user.first_name
            elif hasattr(update.message.forward_origin, 'chat'):
                # Forwarded from a channel/group
                autor = update.message.forward_origin.chat.title
            else:
                autor = 'Unknown'
        else:
            autor = update.message.from_user.first_name

        logger.info(f"Author: {autor}")

        try:
            logger.info("Calling update_file...")
            result = await update_file(text=message, autor=autor, urls=urls)
            
            if result is True:
                logger.info("File updated successfully")
                # Add reaction on success
                try:
                    await context.bot.set_message_reaction(
                        chat_id=update.effective_chat.id,
                        message_id=update.message.message_id,
                        reaction=[ReactionTypeEmoji("👍")]
                    )
                except Exception as reaction_error:
                    logger.warning(f"Could not set reaction: {reaction_error}")
            else:
                logger.error(f"update_file returned error: {result}")
                # Add reaction on error
                try:
                    await context.bot.set_message_reaction(
                        chat_id=update.effective_chat.id,
                        message_id=update.message.message_id,
                        reaction=[ReactionTypeEmoji("👎")]
                    )
                except Exception as reaction_error:
                    logger.warning(f"Could not set reaction: {reaction_error}")
                
                # Send error message
                await update.message.reply_text(f"Error: {result}")
            
        except Exception as e:
            logger.error(f"Exception in echo handler: {e}")
            # Add reaction on error
            try:
                await context.bot.set_message_reaction(
                    chat_id=update.effective_chat.id,
                    message_id=update.message.message_id,
                    reaction=[ReactionTypeEmoji("👎")]
                )
            except Exception as reaction_error:
                logger.warning(f"Could not set reaction: {reaction_error}")
            
            # Send error message
            await update.message.reply_text(f"Error: {e}")


def main() -> None:
    """Start the bot."""
    # Create the Application and pass it your bot's token.
    application = ApplicationBuilder().token(TELEGRAM_BOT_TOKEN).build()
    
    # on different commands - answer in Telegram
    application.add_handler(CommandHandler("start", start))

    # on non command i.e message - echo the message on Telegram
    application.add_handler(MessageHandler(filters.ALL, echo))

    # Run the bot until the user presses Ctrl-C
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
   