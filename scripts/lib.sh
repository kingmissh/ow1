#!/bin/bash
# lib.sh - 共享函数库

# 获取仓库根目录
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# 获取配置存储路径
get_repo_store() {
    echo "$(get_repo_root)/.config-store"
}

# 备份文件/目录
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup.$(date +%s)"
        mv "$target" "$backup"
        echo "$backup"
        return 0
    fi
    return 1
}

# 创建软链接（带备份）
create_symlink() {
    local store_path="$1"
    local target="$2"
    local name="$3"
    
    if [ ! -d "$store_path" ]; then
        return 1
    fi
    
    # 确保父目录存在
    mkdir -p "$(dirname "$target")"
    
    # 备份原配置
    if backup_if_exists "$target" >/dev/null 2>&1; then
        echo "   📝 备份原配置"
    fi
    
    # 删除现有链接或目录
    rm -rf "$target"
    
    # 建立软链接
    ln -s "$store_path" "$target"
    echo "   ✅ $target"
    return 0
}

# 注入 Secret
inject_secret() {
    local key_name="$1"
    local target_file="$2"
    local json_key="${3:-api_key}"
    
    if [ -z "${!key_name}" ]; then
        return 1
    fi
    
    mkdir -p "$(dirname "$target_file")"
    echo "{\"$json_key\": \"${!key_name}\"}" > "$target_file"
    chmod 600 "$target_file"
    echo "   ✅ $key_name"
    return 0
}

# 设置权限
tighten_permissions() {
    local dir="$1"
    if [ -d "$dir" ]; then
        chmod 700 "$dir"
        find "$dir" -type f -exec chmod 600 {} \;
        echo "   ✅ $dir (700)"
    fi
}

# 检查依赖命令
check_dependencies() {
    local deps=("$@")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "❌ 缺少依赖: $dep" >&2
            return 1
        fi
    done
    return 0
}

# 读取配置映射文件到关联数组
# 用法: load_config_mapping MAPPING
# 注意: 需要在调用脚本中先声明: declare -A MAPPING
load_config_mapping() {
    local -n mapping_ref=$1
    local repo_root="$(get_repo_root)"
    local mapping_file="$repo_root/.config-mapping"
    
    # 清空数组
    mapping_ref=()
    
    if [ -f "$mapping_file" ]; then
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            # 去除空格并展开 $HOME
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            value="${value/\$HOME/$HOME}"
            mapping_ref["$key"]="$value"
        done < "$mapping_file"
    fi
    
    # 默认映射（如果配置文件为空）
    if [ ${#mapping_ref[@]} -eq 0 ]; then
        mapping_ref["openclaw"]="$HOME/.openclaw"
        mapping_ref["opencode"]="$HOME/.config/opencode"
    fi
}
