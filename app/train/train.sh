NAMESPACE=$1
BUCKET=$2
OBJECT_NAME=$3
WORK_DIR=$(pwd)

# Installing dependencies
sudo dnf install wget git git-lfs rustc cargo unzip zip -y
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Creating folders
mkdir -p $WORK_DIR/sks/img
mkdir -p $WORK_DIR/sks/reg
mkdir -p $WORK_DIR/output
mkdir -p $WORK_DIR/sks/log

# Getting images
oci os object get -ns $NAMESPACE -bn $BUCKET –name $OBJECT_NAME –file imgs.zip
unzip -jo imgs.zip -d $WORK_DIR/sks/img/1_sks\ person

# Preparing for training
git clone https://github.com/bmaltais/kohya_ss.git
wget -O $WORK_DIR/kohya_ss/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

cd $WORK_DIR/kohya_ss && bash $WORK_DIR/kohya_ss/setup.sh
source $WORK_DIR/kohya_ss/venv/bin/activate && accelerate config default

# Launching training
cd $WORK_DIR/kohya_ss
accelerate launch  "./sdxl_train_network.py" \
  --enable_bucket \
  --min_bucket_reso=256 \
  --max_bucket_reso=2048 \
  --pretrained_model_name_or_path="$WORK_DIR/kohya_ss/sd_xl_base_1.0.safetensors" \
  --train_data_dir="$WORK_DIR/sks/img" \
  --resolution="1024,1024" \
  --output_dir="$WORK_DIR/output" \
  --network_alpha="1" \
  --save_model_as=safetensors \
  --network_module=networks.lora \
  --text_encoder_lr=0.0004 \
  --unet_lr=0.0004 \
  --network_dim=128 \
  --output_name="sks" \
  --lr_scheduler_num_cycles="10" \
  --no_half_vae --learning_rate="0.0004" \
  --lr_scheduler="cosine" \
  --train_batch_size="1" \
  --max_train_steps="800" \
  --mixed_precision="fp16" \
  --save_precision="fp16" \
  --optimizer_type="adafactor" \
  --cache_latents \
  --cache_latents_to_disk \
  --gradient_checkpointing \
  --optimizer_args scale_parameter=False relative_step=False warmup_init=False \
  --max_data_loader_n_workers="0" \
  --bucket_reso_steps=64 \
  --xformers \
  --bucket_no_upscale
