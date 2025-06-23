# Jupyter Lab Configuration for deal.II Development Environment

import os

# Server configuration
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = int(os.environ.get('JUPYTER_PORT', 8888))
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True

# Security settings
c.ServerApp.token = os.environ.get('JUPYTER_TOKEN', '')
c.ServerApp.password = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True

# File and directory settings
c.ServerApp.root_dir = '/workspace'
c.ServerApp.notebook_dir = '/workspace'

# Terminal settings for better development experience
c.ServerApp.terminado_settings = {
    'shell_command': ['/bin/bash']
}

# Enable extensions and features
c.LabApp.check_for_updates_class = 'jupyterlab.NeverCheckForUpdate'

# Resource limits and performance
c.ServerApp.max_buffer_size = 268435456  # 256MB
c.ServerApp.max_body_size = 268435456    # 256MB

# Logging configuration
c.Application.log_level = 'INFO'

# File manager configuration
c.ContentsManager.delete_to_trash = True
c.ContentsManager.pre_save_hook = None

# Session and kernel management
c.MappingKernelManager.default_kernel_name = 'python3'
c.Session.key = b''

# WebSocket configuration
c.ServerApp.websocket_url = ''

# Authentication (disabled for development environment)
c.ServerApp.disable_check_xsrf = True

# Custom extensions and widgets
c.ServerApp.jpserver_extensions = {
    'jupyter_lsp': True,
    'jupyterlab': True,
}

# Environment variables for kernels
c.KernelSpecManager.ensure_native_kernel = True

# Deal.II specific environment setup
kernel_env = {
    'DEAL_II_DIR': '/usr/local',
    'LD_LIBRARY_PATH': '/usr/local/lib',
    'PKG_CONFIG_PATH': '/usr/local/lib/pkgconfig',
    'PATH': '/opt/conda/envs/dealii-dev/bin:' + os.environ.get('PATH', ''),
}

# Apply environment to all kernels
c.KernelManager.kernel_cmd = []
c.KernelManager.env = kernel_env
