import os

# Set GitPython refresh environment variable to suppress warnings
os.environ['GIT_PYTHON_REFRESH'] = 'quiet'

import git
from dotenv import load_dotenv
import time
import datetime
import re

# Configure git executable path for systemd environment
git.Git.git_executable = '/usr/bin/git'

# Configure SSH for git operations
os.environ['GIT_SSH_COMMAND'] = 'ssh -o StrictHostKeyChecking=no'

load_dotenv()

REPO_URL = os.getenv("REPO_URL")
GIT_TOKEN = os.getenv("GIT_TOKEN")
OBSIDIAN_FILE = os.getenv('FILE_NAME')
LOCAL_REPO = os.getenv("REPO_NAME")


async def update_file(autor = None, text = '', urls = None):

    print(f"Updating file with text: {text}")
    commit_day = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    try:
        result = load_from_git()
        if result is not True:
            print(f"Git load error: {result}")
            return result
    except Exception as e:
        print(f"Exception in load_from_git: {e}")
        return str(e)
    
    file_path = os.path.join(LOCAL_REPO, OBSIDIAN_FILE)
    print(f"Writing to file: {file_path}")
    
    try:
        with open(file_path, 'a', encoding='utf-8') as file:
            file.write(f'\n')
            file.write(f'\n---')
            file.write(f'\nавтор: [[{autor}]]')
            file.write(f'\nДата: {commit_day}')
            file.write(f'\nТекст:')
            file.write(f'\n{text}')
            print(f"URLs: {urls}")
            if urls:
                file.write(f'\nСсылки:')
                for i in urls:
                    file.write(f'\n{i}')
            # Добавляем найденные ссылки

    except Exception as e:
        print(f"Error writing to file: {e}")
        return str(e)
        
    try: 
        result = await save_to_git()
        if result is not True:
            print(f"Git save error: {result}")
            return result
        print("File updated and saved to git successfully")
        return True
    except Exception as e:
        print(f"Exception in save_to_git: {e}")
        return str(e)
        

def load_from_git():

    print(f"Loading from git: {REPO_URL}")

    # Клонируем или обновляем локально
    if not os.path.exists(LOCAL_REPO):
        try:
            print("Cloning repository...")
            repo = git.Repo.clone_from(REPO_URL, LOCAL_REPO)
            print("Repository cloned successfully")
            return True
        except Exception as e:
            print(f"Error cloning repository: {e}")
            return str(e)
    else:
        try:
            print("Pulling latest changes...")
            repo = git.Repo(LOCAL_REPO)
            origin = repo.remote(name='origin')
            origin.pull()
            print("Repository updated successfully")
            return True
        except Exception as e:
            print(f"Error pulling changes: {e}")
            try:
                print("Trying to re-clone repository...")
                import shutil
                shutil.rmtree(LOCAL_REPO)
                repo = git.Repo.clone_from(REPO_URL, LOCAL_REPO)
                print("Repository re-cloned successfully")
                return True
            except Exception as e2:
                print(f"Error re-cloning repository: {e2}")
                return str(e2)

async def save_to_git():

    

    print("Saving to git...")

    try:
        # Open the existing repo, do not clone every time
        repo = git.Repo(LOCAL_REPO)
        
        # Stage all changes (including new files)
        print("Staging changes...")
        repo.git.add(A=True)
        
        # Check if there are any staged changes
        # Handle empty repository case
        try:
            staged_files = repo.index.diff("HEAD")
            has_staged_changes = bool(staged_files)
        except git.exc.BadName:
            # Repository is empty (no HEAD), check for staged files using git command
            try:
                staged_output = repo.git.diff("--cached", "--name-only")
                has_staged_changes = bool(staged_output.strip())
            except:
                has_staged_changes = False
        
        # Also check for untracked files
        has_untracked_files = bool(repo.untracked_files)
        
        if not has_staged_changes and not has_untracked_files:
            print("No changes to commit")
            return True

        # Create a commit message with current date and time
        commit_day = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        commit_message = f'Update: {commit_day}'
        print(f"Committing with message: {commit_message}")
        
        repo.index.commit(commit_message)
        
        print("Pushing to remote...")
        origin = repo.remote(name='origin')
        origin.push()
        
        print("Successfully pushed to git")
        return True
    except Exception as e: 
        print(f"Error saving to git: {e}")
        return str(e)

if __name__ == '__main__':
    
    update_file(text='мой текст')
