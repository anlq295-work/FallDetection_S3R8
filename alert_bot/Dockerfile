FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt /app/alert_bot/requirements.txt
RUN pip install --no-cache-dir -r /app/alert_bot/requirements.txt

COPY . /app/alert_bot/

EXPOSE 8080

CMD ["python", "-m", "alert_bot.run"]
