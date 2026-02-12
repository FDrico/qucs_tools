# qucs_tools
qucstudio and qucs-s on a single docker

# How to run
Launch qucs-s: `docker exec -it qucs_lab qucs-launch qucs-s`

Launch qucStudio: `docker exec -it qucs_lab qucs-launch studio`

# Folders needed
Create the folder `my_circuits` on the current directory to be able to share circuits with the container.

# Aliases
Create the following aliases to make it easier to run the aplications

```
alias qucs='docker exec -it qucs_lab qucs-launch qucs-s'
alias studio='docker exec -it qucs_lab qucs-launch studio'
```
