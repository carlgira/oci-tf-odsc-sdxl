import os
import ocifs
import glob

###############################
############################### Fetch env variable
###############################

full_input_folder = os.environ.get("full_input_folder", "no_input_folder")  #default

print("Full input folder used is " + full_input_folder)


###############################
############################### directories etc
###############################

##kohya_ss stored in Job Artifacts

## get model weights
os.system("mkdir -p stable-diffusion-xl-base-1.0 && wget -O stable-diffusion-xl-base-1.0/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors")

## activate
# os.system("bash kohya_ss/setup.sh")
# os.system("source kohya_ss/venv/bin/activate")

## create local folders
os.system("mkdir -p 'sks/img/1_sks person'")  # cropped and resized images as input for training
os.system("mkdir -p sks/reg")
os.system("mkdir -p sks/model")
os.system("mkdir -p sks/log")
os.system("mkdir -p output")  #same as in sdxl_minimal_inference.py


###############################
############################### Get images from bucket and put in ..1_sk / person folder
###############################

   
profile_image_loc = "./sks/img/1_sks person"
print("Local folder for iamges is " + profile_image_loc)
        
#get the image from the bucket and store locally
fs = ocifs.OCIFileSystem()
    
#list jpg files
list_files = fs.ls(full_input_folder)
print(list_files)
    
for image in list_files:
    fs.invalidate_cache(full_input_folder)
    fs.get(image, profile_image_loc , recursive=True, refresh=True)
    print("storing image " + image + " in " + profile_image_loc)
        
print("Profile images are stored locally at " + profile_image_loc)
print(glob.glob(profile_image_loc)) 


###############################
############################### Stable Diffusion
###############################

os.system("accelerate launch  kohya_ss/sdxl_train_network.py \
  --enable_bucket \
  --min_bucket_reso=256 \
  --max_bucket_reso=2048 \
  --pretrained_model_name_or_path=stable-diffusion-xl-base-1.0/sd_xl_base_1.0.safetensors \
  --train_data_dir=sks/img \
  --resolution='1024,1024' \
  --output_dir=sks/output \
  --network_alpha='1' \
  --save_model_as=safetensors \
  --network_module=networks.lora \
  --text_encoder_lr=0.0004 \
  --unet_lr=0.0004 \
  --network_dim=128 \
  --output_name='sks' \
  --lr_scheduler_num_cycles='10' \
  --no_half_vae --learning_rate='0.0004' \
  --lr_scheduler='cosine' \
  --train_batch_size='1' \
  --max_train_steps='1200' \
  --mixed_precision='fp16' \
  --save_precision='fp16' \
  --optimizer_type='adafactor' \
  --cache_latents \
  --cache_latents_to_disk \
  --gradient_checkpointing \
  --optimizer_args scale_parameter=False relative_step=False warmup_init=False \
  --max_data_loader_n_workers='0' \
  --bucket_reso_steps=64 \
  --xformers \
  --bucket_no_upscale")

print("----------------------- Training done")

###############################
############################### Generate image
###############################

os.system("python kohya_ss/sdxl_minimal_inference.py --ckpt_path stable-diffusion-xl-base-1.0/sd_xl_base_1.0.safetensors --output_dir=output --lora_weights sks/output/sks.safetensors --prompt 'ultra realistic illustration, ((sks man)) in a red bull racing formula 1 suit intricate, elegant, no helmet, headphones, highly detailed, digital painting, artstation, concept art, smooth, sharp focus, illustration, art by artgerm and greg rutkowski and alphonse mucha'")

os.system("mv sks/output/sks.safetensors output")

###############################
############################### Result image to bucket happens by calling the Job as env variable
###############################


