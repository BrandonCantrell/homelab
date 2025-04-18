from constructs import Construct
from cdktf import App, TerraformStack
from cdktf_cdktf_provider_docker.image import Image
from cdktf_cdktf_provider_docker.container import Container
from cdktf_cdktf_provider_docker.provider import DockerProvider


class MyStack(TerraformStack):
    def __init__(self, scope: Construct, ns: str):
        super().__init__(scope, ns)

        DockerProvider(self, 'docker')

        docker_image = Image(self, 'nginxImage',
            name='nginx:latest',
            keep_locally=False)

        Container(self, 'nginxContainer',
            name='nginx',
            image=docker_image.name,
            ports=[{
                'internal': 80,
                'external': 8000
            }])


app = App()
MyStack(app, "nginx-basic")

app.synth()