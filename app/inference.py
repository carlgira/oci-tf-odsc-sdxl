import json
import os
import json
from urllib import request
import random
import os
import time
from PIL import Image

prompt_text = """
{
  "4": {
    "inputs": {
      "ckpt_name": "sd_xl_base_1.0.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "6": {
    "inputs": {
      "text": "",
      "clip": [
        "23",
        1
      ]
    },
    "class_type": "CLIPTextEncode"
  },
  "7": {
    "inputs": {
      "text": "",
      "clip": [
        "23",
        1
      ]
    },
    "class_type": "CLIPTextEncode"
  },
  "8": {
    "inputs": {
      "samples": [
        "17",
        0
      ],
      "vae": [
        "4",
        2
      ]
    },
    "class_type": "VAEDecode"
  },
  "9": {
    "inputs": {
      "filename_prefix": "base_output",
      "images": [
        "8",
        0
      ]
    },
    "class_type": "SaveImage"
  },
  "17": {
    "inputs": {
      "seed": 166294930740984,
      "steps": 30,
      "cfg": 7,
      "sampler_name": "dpmpp_2s_ancestral",
      "scheduler": "normal",
      "denoise": 1,
      "model": [
        "23",
        0
      ],
      "positive": [
        "6",
        0
      ],
      "negative": [
        "7",
        0
      ],
      "latent_image": [
        "21",
        0
      ]
    },
    "class_type": "KSampler"
  },
  "21": {
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    },
    "class_type": "EmptyLatentImage"
  },
  "23": {
    "inputs": {
      "lora_name": "sks.safetensors",
      "strength_model": 1,
      "strength_clip": 1,
      "model": [
        "4",
        0
      ],
      "clip": [
        "4",
        1
      ]
    },
    "class_type": "LoraLoader"
  }
}
"""

prompt_text = json.loads(prompt_text)

def wait_for_new_png(directory):
    files_start = os.listdir(directory)
    count = 0
    while True and count < 180:
        time.sleep(1)
        count += 1
        files_now = os.listdir(directory)
        new_files = set(files_now) - set(files_start)
        for file in new_files:
            if file.endswith(".png"):
                return os.path.join(directory, file)
    return None

def generate_image(prompt, negative_prompt="", seed=None):
    prompt_text["6"]["inputs"]["text"] = prompt
    prompt_text["7"]["inputs"]["text"] = negative_prompt
    if seed is None:
        prompt_text["17"]["inputs"]["seed"] = str(random.randint(0, pow(2, 32)))
    else:
        prompt_text["17"]["inputs"]["seed"] = seed
    
    p = {"prompt": prompt_text}
    data = json.dumps(p).encode('utf-8')
    req =  request.Request("http://127.0.0.1:8188/prompt", data=data)
    request.urlopen(req)
    
    image_file = wait_for_new_png('ComfyUI/output/')
    
    if image_file is None:
        return image_file
    
    im = Image.open(image_file)
    
    return im
