bindkey -v
export KEYTIMEOUT=1

# Ctrl-h/j/k/l
bindkey -M viins '^H' backward-char
bindkey -M viins '^J' down-line-or-history
bindkey -M viins '^K' up-line-or-history
bindkey -M viins '^L' forward-char

# Alt-h/l 移动 5 字符
zle_move_left_5() {
  repeat 5 zle backward-char
}

zle_move_right_5() {
  repeat 5 zle forward-char
}

zle -N zle_move_left_5
zle -N zle_move_right_5

bindkey -M viins '^[h' zle_move_left_5
bindkey -M viins '^[l' zle_move_right_5

# Alt-j/k 历史上下移动 5 次
zle_up_5() {
  repeat 5 zle up-line-or-history
}

zle_down_5() {
  repeat 5 zle down-line-or-history
}

zle -N zle_up_5
zle -N zle_down_5

bindkey -M viins '^[j' zle_down_5
bindkey -M viins '^[k' zle_up_5

# Alt-e / Alt-b word 移动
bindkey -M viins '^[e' forward-word
bindkey -M viins '^[b' backward-word

# Alt-Shift-e / Alt-Shift-b 移动 3 个 word
zle_forward_word_3() {
  repeat 3 zle forward-word
}

zle_backward_word_3() {
  repeat 3 zle backward-word
}

zle -N zle_forward_word_3
zle -N zle_backward_word_3

bindkey -M viins '^[E' zle_forward_word_3
bindkey -M viins '^[B' zle_backward_word_3
# 向前删除一个 word：Alt + Backspace
bindkey '^[^?' backward-kill-word

# 向后删除一个 word：Alt + d
bindkey '^[d' kill-word
