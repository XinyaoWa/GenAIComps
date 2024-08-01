max_input_tokens=2048
max_total_tokens=4096

port_number=8081
model_name="meta-llama/Meta-Llama-3-8B-Instruct"
HUGGING_FACE_HUB_TOKEN=""
volume=""
workdir=""

docker run --rm -it \
    --name="ChatQnA_server" \
    -p $port_number:80 \
    -v $volume:/data \
    -v $workdir:/home/work/ \
    --runtime=habana \
    -e HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKE \
    -e HABANA_VISIBLE_DEVICES=all \
    -e OMPI_MCA_btl_vader_single_copy_mechanism=none \
    --cap-add=sys_nice \
    --ipc=host \
    -e HTTPS_PROXY=$https_proxy \
    -e HTTP_PROXY=$https_proxy \
    ghcr.io/huggingface/tgi-gaudi:2.0.1 \
    --model-id $model_name \
    --max-input-tokens $max_input_tokens \
    --max-total-tokens $max_total_tokens

## optimize batch size
docker run -it --rm\
    --name="ChatQnA_server" \
    -p $port_number:80 \
    -v $volume:/data \
    -v $workdir:/home/work/ \
    --runtime=habana \
    -e HUGGING_FACE_HUB_TOKEN="" \
    -e HABANA_VISIBLE_DEVICES=all \
    -e OMPI_MCA_btl_vader_single_copy_mechanism=none \
    -e PREFILL_BATCH_BUCKET_SIZE=1 \
    -e BATCH_BUCKET_SIZE=8 \
    --cap-add=sys_nice \
    --ipc=host \
    -e HTTPS_PROXY=$https_proxy \
    -e HTTP_PROXY=$https_proxy \
    ghcr.io/huggingface/tgi-gaudi:2.0.1 \
    --model-id $model_name \
    --max-input-tokens $max_input_tokens \
    --max-total-tokens $max_total_tokens \
    --max-batch-total-tokens 65536 \
    --max-batch-prefill-tokens 4096

##########################################################################################################################
## multi cards
# docker run --rm -it --name="ChatQnA_server" -p $port_number:80 -v $volume:/data -v $workdir:/home/work/ --runtime=habana -e HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN -e PT_HPU_ENABLE_LAZY_COLLECTIVES=true -e HABANA_VISIBLE_DEVICES=all -e OMPI_MCA_btl_vader_single_copy_mechanism=none --cap-add=sys_nice --ipc=host -e HTTPS_PROXY=$https_proxy -e HTTP_PROXY=$https_proxy ghcr.io/huggingface/tgi-gaudi:2.0.1 --model-id $model_name --sharded true --num-shard 4 --max-input-tokens 1024 --max-total-tokens 2048

# docker pull ghcr.io/huggingface/tgi-gaudi:2.0.1