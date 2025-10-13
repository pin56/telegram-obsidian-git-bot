FROM python:3.12-slim

# Prevent python from writing .pyc files and enable unbuffered logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install git and SSH client for GitPython operations
RUN apt-get update \
    && apt-get install -y --no-install-recommends git openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies first (better layer caching)
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Copy application code
COPY bot.py redactor.py ./

# Default command: start the bot
CMD ["python", "bot.py"]


