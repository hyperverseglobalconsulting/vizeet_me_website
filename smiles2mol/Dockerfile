# Build Stage
FROM public.ecr.aws/lambda/python:3.13 as build

# Install build tools
RUN dnf install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    python3-devel \
    expat-devel \
    && dnf clean all

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -t ${LAMBDA_TASK_ROOT}

# Runtime Stage
FROM public.ecr.aws/lambda/python:3.13

# Install runtime dependencies
RUN dnf install -y \
    libXrender \
    libXext \
    libxcb \
    libX11 \
    libXi \
    libSM \
    libICE \
    expat \
    libpng \
    fontconfig \
    freetype \
    && dnf clean all

# Copy dependencies and code
COPY --from=build ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Set library path
ENV LD_LIBRARY_PATH=/var/lang/lib:/usr/lib64:$LD_LIBRARY_PATH

CMD ["lambda_function.lambda_handler"]
