from flask import Flask, escape, request

app = Flask(__name__)

@app.route('/')
def hello_world():
    name = request.args.get("name", "World")
    return f'Hello/Hola/Ciao, {escape(name)}!'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
