import os
from git import Repo
from dotenv import load_dotenv
import time
import datetime

load_dotenv()

GIT_TOKEN = os.getenv("GIT_TOKEN")
OBSIDIAN_FILE = os.getenv('FILE_NAME')

async def update_file(autor = None, text = ''):
    commit_day = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        e = load_from_git()
    except:
        return e
    
    with open('obsidian_files/' + OBSIDIAN_FILE, 'a', encoding='utf-8') as file:
        file.write(f'\n---')
        file.write(f'\nавтор: [[{autor}]]')
        file.write(f'\nДата: {commit_day}')
        file.write(f'\nТекст:')
        file.write(f'\n{text}')
        
        file.close()
    try: 
        e = await save_to_git()
        return True
    except:
        return e
        

def load_from_git():

    REPO_URL = f"https://{GIT_TOKEN}@github.com/pin-obs/obs-vault.git"
    LOCAL_REPO = "obsidian_files"


    # Клонируем или обновляем локально
    if not os.path.exists(LOCAL_REPO):
        repo = Repo.clone_from(REPO_URL, LOCAL_REPO)
    else:
        try:
            repo = Repo(LOCAL_REPO)
            repo.remote().pull()
            return True
        except Exception as e:
            repo = Repo.clone_from(REPO_URL, LOCAL_REPO)
            return e

async def save_to_git():
    REPO_URL = f"https://{GIT_TOKEN}@github.com/pin-obs/obs-vault.git"
    LOCAL_REPO = "obsidian_files"

    # Open the existing repo, do not clone every time
    repo = Repo(LOCAL_REPO)

    # Stage all changes
    repo.git.add(A=True)

    # Create a commit message with current date and time
    commit_day = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        repo.index.commit(f'Update: {commit_day}')
        origin = repo.remote(name='origin')
        origin.push()
        return True
    except Exception as e: 
        return e

if __name__ == '__main__':
    
    update_file(text='мой тексь')
