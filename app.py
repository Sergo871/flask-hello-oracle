import os

import oracledb
from dotenv import load_dotenv
from flask import Flask

load_dotenv()

app = Flask(__name__)

DB_USER = os.environ.get("DB_USER", "ADMIN")
DB_PASSWORD = os.environ["DB_PASSWORD"]
DB_DSN = os.environ.get("DB_DSN", "database_high")
WALLET_DIR = os.environ.get("WALLET_DIR", "/home/opc/wallet")
WALLET_PASSWORD = os.environ.get("WALLET_PASSWORD")


def get_connection():
    return oracledb.connect(
        user=DB_USER,
        password=DB_PASSWORD,
        dsn=DB_DSN,
        config_dir=WALLET_DIR,
        wallet_location=WALLET_DIR,
        wallet_password=WALLET_PASSWORD,
    )


@app.route("/")
def hello():
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 'hello world' FROM DUAL")
            result = cursor.fetchone()
    return f"<h1>{result[0]}</h1>"


if __name__ == "__main__":
    app.run(host=os.environ.get("HOST", "0.0.0.0"), port=int(os.environ.get("PORT", "5000")))
