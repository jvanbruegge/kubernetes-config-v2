Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"
  config.vm.network "private_network", ip: "192.168.99.100"
  config.vm.hostname = "kube-master"
  config.vm.provider "libvirt" do |v|
    v.memory = 4096
    v.cpus = 2
  end
end
