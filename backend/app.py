from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS

app = Flask(__name__)

# Enable CORS for all routes and origins
CORS(app)

# Sample in-memory task storage
tasks = []

@app.route('/tasks', methods=['GET'])
def get_tasks():
    return jsonify(tasks)

@app.route('/add', methods=['POST'])
def add_task():
    task = request.json.get('task')
    if task:
        tasks.append(task)
        return jsonify({"message": "Task added"}), 201
    return jsonify({"message": "No task provided"}), 400

@app.route('/delete', methods=['POST'])
def delete_task():
    task = request.json.get('task')
    if task in tasks:
        tasks.remove(task)
        return jsonify({"message": "Task deleted"}), 200
    return jsonify({"message": "Task not found"}), 404

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)