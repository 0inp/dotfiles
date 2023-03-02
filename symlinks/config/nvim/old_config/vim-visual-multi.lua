local status_ok, vim_visual_multi = pcall(require, "vim-visual-multi")
if not status_ok then
	return
end

vim_visual_multi.setup()
