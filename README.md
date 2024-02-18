# Serhan Ekici's Webpage

## Dependencies

* POSIX tools
* [pandoc](https://pandoc.org/)
* [jq](https://jqlang.github.io/jq/)

## Instructions

```
chmod +x gen
./gen
```

## Update Posts Using Vim Auto Commands

Add following to your Vim or Neovim config:

```
autocmd BufWritePost */website/*/*.md,*/website/*/*.html,*/website/*/conf ! sed -i "s/^date_updated=.*/date_updated=$(date +"\"\%a, \%d \%b \%Y \%H:\%M:\%S \%z\"")/" %:p:h/conf
```
