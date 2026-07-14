import threading
import requests
import sys

URL = sys.argv[1]

def worker():
    session = requests.Session()

    while True:
        try:
            session.get(URL, timeout=5)
        except requests.RequestException:
            pass

THREADS = 400

for _ in range(THREADS):
    threading.Thread(target=worker, daemon=True).start()

print(f'Generando traffico verso {URL} con {THREADS} thread...')

threading.Event().wait()