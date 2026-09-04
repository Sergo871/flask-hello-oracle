from flask import Flask
import oracledb

app = Flask(__name__)

un = "ADMIN"
pw = "Database123125"
dsn = "database_high"

@app.route("/")
def hello():
    connection = oracledb.connect(
        user=un,
        password=pw,
        dsn=dsn,
        config_dir="/home/opc/wallet",
        wallet_location="/home/opc/wallet",
        wallet_password="Wallet123125"
    )
    cursor = connection.cursor()
    cursor.execute("SELECT 'hello world' FROM DUAL")
    result = cursor.fetchone()
    connection.close()
    return f"<h1>{result[0]}</h1>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)