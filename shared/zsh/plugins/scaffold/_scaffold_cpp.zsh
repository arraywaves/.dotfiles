# ── C++/CMake ─────────────────────────────────────────────────────────────────
_scaffold_cpp() {
  echo "   Setting up C++23 / CMake..."
  mkdir -p src include

  cat > CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.20)
project($1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(\${PROJECT_NAME} src/main.cpp)
target_include_directories(\${PROJECT_NAME} PRIVATE include)
EOF

  cat > src/main.cpp <<EOF
#include <iostream>

int main() {
    std::cout << "$1\n";
    return 0;
}
EOF

  cat > .gitignore <<EOF
build/
*.o
*.a
*.out
compile_commands.json
.cache/

# LLMs
.claude/
EOF

  local DOTFILES_CLANG="$HOME/.dotfiles/shared/clang-format"
  if [[ -f "$DOTFILES_CLANG/.clang-format" ]]; then
    cp "$DOTFILES_CLANG/.clang-format" .clang-format
  fi
}
