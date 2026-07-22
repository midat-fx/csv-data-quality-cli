# bash completion for csvq. Source it or drop into /etc/bash_completion.d/.
_csvq() {
  local cur prev cmds
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cmds="audit stats validate diff dedupe normalize version help"
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    return
  fi
  case "$prev" in
    --schema|-o) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    -d|--delim)  COMPREPLY=( $(compgen -W "comma semicolon tab pipe" -- "$cur") ); return ;;
  esac
  case "${COMP_WORDS[1]}" in
    audit)    COMPREPLY=( $(compgen -W "-o -d --delim --strict" -- "$cur") ) ;;
    validate) COMPREPLY=( $(compgen -W "--schema -d --delim" -- "$cur") ) ;;
    diff)     COMPREPLY=( $(compgen -W "--key -d --delim" -- "$cur") ) ;;
    dedupe)   COMPREPLY=( $(compgen -W "--key -d --delim" -- "$cur") ) ;;
    normalize) COMPREPLY=( $(compgen -W "--in-place" -- "$cur") ) ;;
  esac
  [ ${#COMPREPLY[@]} -eq 0 ] && COMPREPLY=( $(compgen -f -- "$cur") )
}
complete -F _csvq csvq csvq.sh
