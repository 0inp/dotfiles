# Update Brew
echo "---- Updating Brew ----"
if [ "$(which "brew")" != "" ]; then
	brew cleanup && brew update && brew upgrade
else
	echo "Brew command not found"
fi
echo "---- END ----"

# Upgrade pip
echo "---- Updating pip ----"
if [ "$(which "python3")" != "" ]; then
	python -m pip install --upgrade pip
else
	echo "python command not found"
fi
echo "---- END ----"

# Update poetry
echo "---- Updating poetry ----"
if [ "$(which "poetry")" != "" ]; then
	poetry self update
else
	echo "poetry command not found"
fi
echo "---- END ----"
# Update nvim
echo "---- Updating nvim ----"
if [ "$(which "nvim")" != "" ]; then
	nvim --headless "+Lazy! sync" +qa
else
	echo "nvim command not found"
fi
echo "---- END ----"
