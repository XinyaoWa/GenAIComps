import requests

url="http://0.0.0.0:8081"
data={'inputs': 'Hello, how are you?', 'parameters': {'max_new_tokens': 1024}}
headers = {"Content-Type": "application/json"}
response = requests.post(url, json=data, headers=headers, stream=True)
print(response.text)