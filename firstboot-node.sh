while : ; do
	command=$(ssh -oConnectTimeout=1 -oStrictHostKeyChecking=no master kubeadm token create --print-join-command)
	[ $? -eq 0 ] && break
done
eval $command
systemctl disable firstboot
