from flask import Flask, request, jsonify, render_template, send_from_directory
from llama_cpp import Llama
from pymongo import MongoClient
from bson import ObjectId
import time
import os
import logging

app = Flask(__name__, template_folder="templates", static_folder="static")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MongoDB setup with environment variable
mongodb_uri = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/chat_app')
client = MongoClient(mongodb_uri)
db = client['chat_app']
chats_collection = db['chats']
messages_collection = db['messages']
profiles_collection = db['profiles']

# Optimized model initialization
llm = Llama(
    model_path="pentest_ai.Q5_K_M.gguf",
    n_ctx=2048,
    n_threads=4,
    n_gpu_layers=0,
    n_batch=512,
    use_mmap=True,
    use_mlock=False
)

def format_prompt(message, history):
    prompt_parts = []
    for user_msg, bot_msg in history:
        prompt_parts.append(f"[INST] {user_msg} [/INST] {bot_msg} </s>")
    prompt_parts.append(f"[INST] {message} [/INST]")
    return "".join(prompt_parts)

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/favicon.ico")
def favicon():
    return send_from_directory(
        os.path.join(app.root_path, 'static'),
        'favicon.ico',
        mimetype='image/vnd.microsoft.icon'
    )

@app.route("/chat", methods=["POST"])
def chat():
    try:
        data = request.get_json()
        user_message = data["message"]
        user_id = data.get("user_id")
        chat_id = data.get("chat_id")
        
        if not chat_id:
            # Create new chat if none exists
            chat = chats_collection.insert_one({
                "user_id": user_id,
                "title": "New Chat",
                "created_at": time.time()
            })
            chat_id = str(chat.inserted_id)
        
        # Get chat history
        history = messages_collection.find({
            "chat_id": chat_id
        }).sort("created_at", 1)
        
        # Format history for prompt
        chat_history = []
        for msg in history:
            if msg["sender"] == "user":
                chat_history.append((msg["content"], ""))
            else:
                if chat_history:
                    chat_history[-1] = (chat_history[-1][0], msg["content"])
        
        # Generate response
        prompt = format_prompt(user_message, chat_history)
        start_time = time.time()
        
        output = llm.create_completion(
            prompt,
            max_tokens=384,
            temperature=0.7,
            top_p=0.9,
            stop=["</s>", "[INST]"],
            repeat_penalty=1.1
        )
        
        response = output["choices"][0]["text"].strip()
        latency = round(time.time() - start_time, 2)
        
        # Save messages
        messages_collection.insert_one({
            "chat_id": chat_id,
            "user_id": user_id,
            "content": user_message,
            "sender": "user",
            "created_at": time.time()
        })
        
        messages_collection.insert_one({
            "chat_id": chat_id,
            "user_id": user_id,
            "content": response,
            "sender": "bot",
            "created_at": time.time()
        })
        
        logger.info(f"Generated in {latency}s (Chat: {chat_id})")
        return jsonify({
            "response": response,
            "latency": latency,
            "chat_id": chat_id
        })
    except Exception as e:
        logger.error(f"Error in chat: {str(e)}", exc_info=True)
        return jsonify({
            "error": "An error occurred while processing your request",
            "details": str(e)
        }), 500

@app.route("/chats", methods=["GET"])
def get_chats():
    try:
        user_id = request.args.get("user_id")
        chats = list(chats_collection.find({"user_id": user_id}).sort("created_at", -1))
        
        # Convert ObjectId to string for JSON serialization
        for chat in chats:
            chat["_id"] = str(chat["_id"])
        
        return jsonify(chats)
    except Exception as e:
        logger.error(f"Error getting chats: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route("/chats/<chat_id>", methods=["PUT"])
def update_chat(chat_id):
    try:
        data = request.get_json()
        chats_collection.update_one(
            {"_id": ObjectId(chat_id)},
            {"$set": {"title": data["title"]}}
        )
        return jsonify({"success": True})
    except Exception as e:
        logger.error(f"Error updating chat: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route("/chats/<chat_id>", methods=["DELETE"])
def delete_chat(chat_id):
    try:
        # Delete all messages in the chat
        messages_collection.delete_many({"chat_id": chat_id})
        # Delete the chat
        chats_collection.delete_one({"_id": ObjectId(chat_id)})
        return jsonify({"success": True})
    except Exception as e:
        logger.error(f"Error deleting chat: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

@app.route("/profile", methods=["GET", "POST", "PUT"])
def handle_profile():
    try:
        if request.method == "GET":
            user_id = request.args.get("user_id")
            profile = profiles_collection.find_one({"user_id": user_id})
            if profile:
                profile["_id"] = str(profile["_id"])
            return jsonify(profile)
        
        elif request.method in ["POST", "PUT"]:
            data = request.get_json()
            user_id = data["user_id"]
            
            update_data = {
                "username": data.get("username"),
                "avatar_url": data.get("avatar_url"),
                "updated_at": time.time()
            }
            
            if request.method == "POST":
                update_data["user_id"] = user_id
                profiles_collection.insert_one(update_data)
            else:
                profiles_collection.update_one(
                    {"user_id": user_id},
                    {"$set": update_data}
                )
            
            return jsonify({"success": True})
            
    except Exception as e:
        logger.error(f"Error handling profile: {str(e)}", exc_info=True)
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False,
        threaded=True
    )