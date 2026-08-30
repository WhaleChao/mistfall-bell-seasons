from __future__ import annotations

import argparse
import json

from websockets.sync.client import connect


def main() -> None:
    parser = argparse.ArgumentParser(description="Stream one real PixelRPG Creator Service showcase")
    parser.add_argument("--token", required=True)
    parser.add_argument("--prompt", default="根據世界觀，替米拉寫一段請求玩家調查鐘塔的兩句對話，語氣克制而溫柔。")
    parser.add_argument("--model-mode", choices=["fast", "quality"], default="fast")
    args = parser.parse_args()

    url = f"ws://127.0.0.1:8765/api/v1/assist/stream?token={args.token}"
    request = {
        "task": "對話草稿",
        "prompt": args.prompt,
        "artifact_type": "dialogues",
        "mode": args.model_mode,
        "max_context_tokens": 4096,
    }
    final_draft = None
    with connect(url, open_timeout=5, close_timeout=5) as websocket:
        websocket.send(json.dumps(request, ensure_ascii=False))
        while True:
            event = json.loads(websocket.recv())
            event_type = event.get("type")
            if event_type == "source":
                print(f"SOURCE {event['source_id']} · {event['path']}")
                print(event.get("excerpt", "")[:300].replace("\n", " "))
            elif event_type == "warning":
                print(f"WARNING {event.get('message', '')}")
            elif event_type == "draft":
                final_draft = event["content"]
            elif event_type == "error":
                print(f"ERROR {event.get('message', 'Unknown Creator Service error')}")
                for validation_error in event.get("validation_errors", []):
                    print(f"  - {validation_error}")
                if event.get("raw"):
                    print("LAST RAW DRAFT")
                    print(str(event["raw"])[:2000])
                raise RuntimeError("Creator Service rejected the draft and did not write project content")
            elif event_type == "done":
                break
    print("\nVALIDATED DRAFT")
    print(json.dumps(final_draft, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
