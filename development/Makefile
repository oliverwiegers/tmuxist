dev:
	cp ../tmux/.tmux.conf ./tmux.config
	cut -c3- ./tmux.config | sed '0,/^EOF$$/d' > ./custom_functions.sh
	sed '1,/^# EOF$$/!d' ./tmux.config > ./tmux.conf

build:
	cat ./tmux.conf > ./tmux.config
	sed 's/^/# /g;s/^# $$/#/g;' custom_functions.sh >> ./tmux.config

deploy:
	cat ./tmux.conf > ./tmux.config
	sed 's/^/# /g;s/^# $$/#/g;' custom_functions.sh >> ./tmux.config
	cp ./tmux.config ../tmux/.tmux.conf

cleanup:
	rm ./tmux.conf ./tmux.config ./custom_functions.sh
