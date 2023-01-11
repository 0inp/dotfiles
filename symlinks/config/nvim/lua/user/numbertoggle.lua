local status_ok, numbertoggle = pcall(require, "numbertoggle")
if not status_ok then
	return
end

numbertoggle.setup()
