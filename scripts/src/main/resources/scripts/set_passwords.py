from common_platform_files.common_methods import NodeConnect
from litp_deploy.litp_setup_nodes import SetupLitpNodes
ai_params = dict()
ai_params["MS_IP"] = "10.44.86.42"
ai_params["NODE_HOSTNAMES"] = "SC-1,SC-2"
SetupLitpNodes(ai_params).setup_litp_nodes()
