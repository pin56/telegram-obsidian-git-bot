import logging
import os

from redactor import update_file
from dotenv import load_dotenv
from telegram import InlineKeyboardButton, Update, InlineKeyboardMarkup, ForceReply
from telegram.ext import ApplicationBuilder, CallbackQueryHandler, CommandHandler, ContextTypes, MessageHandler, filters

load_dotenv()

TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
USER_ID = os.getenv('USER_ID')


users = USER_ID.replace(',', ' ').split()

# Enable logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.INFO
)
# set higher logging level for httpx to avoid all GET and POST requests being logged
logging.getLogger("httpx").setLevel(logging.WARNING)

logger = logging.getLogger(__name__)


# Define a few command handlers. These usually take the two arguments update and
# context.
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Send a message when the command /start is issued."""
    user = update.effective_user
    print(users)

    if user.id in users:
        await update.message.reply_html(
            rf"Hi {user.mention_html()}!",
            reply_markup=ForceReply(selective=True),
        )



async def echo(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Echo the user message."""

    # Extract message text
    if update.message.text is not None:
        message = update.message.text
    else:
        message = update.message.caption
    
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

    e = await update_file(text=message, autor=autor)

    try: 
        await update.message.reply_text(e)
    except Exception as e:
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
   