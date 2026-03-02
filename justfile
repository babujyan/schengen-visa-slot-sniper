# Schengen Slot Sniper — build recipes

# Build Tailwind CSS (minified)
build:
    bunx @tailwindcss/cli -i resources/input.css -o resources/dist/output.css --minify

# Watch Tailwind CSS for changes
watch:
    bunx @tailwindcss/cli -i resources/input.css -o resources/dist/output.css --watch
