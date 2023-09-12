if ($(which nvidia-smi > /dev/null 2>&1 )) ; then
  CUDAROOT=/usr/local/cuda

  export PATH=$CUDAROOT/bin:$PATH
  export LD_LIBRARY_PATH=$CUDAROOT/lib64:$LD_LIBRARY_PATH
  export CFLAGS="-I$CUDAROOT/include $CFLAGS"
  export CUDA_HOME=$CUDAROOT
  export CUDA_PATH=$CUDAROOT
fi
