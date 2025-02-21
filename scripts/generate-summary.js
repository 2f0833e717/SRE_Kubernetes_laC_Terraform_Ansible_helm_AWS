const fs = require('fs');
const path = require('path');

/**
 * SUMMARY.mdを生成
 * 
 * docsディレクトリ内のMarkdownファイルを走査し、目次を生成します。
 * - ディレクトリ構造を維持
 * - ディレクトリを先頭に配置（apiディレクトリは最後に配置）
 * - 同じタイプ内ではアルファベット順にソート
 * - book, node_modules, .git などの特定ディレクトリを除外
 */
function generateSummary() {
    const docsDir = path.join(__dirname, '../docs');
    const summary = ['# Summary\n'];
    let apiContent = [];

    function processDirectory(dir, depth = 0, isApi = false) {
        const files = fs.readdirSync(dir);

        // ファイルとディレクトリを分離してソート
        const sortedItems = files
            .map(file => ({
                name: file,
                path: path.join(dir, file),
                isDirectory: fs.statSync(path.join(dir, file)).isDirectory()
            }))
            .sort((a, b) => {
                // ディレクトリを先に、同じタイプ内ではアルファベット順
                if (a.isDirectory !== b.isDirectory) {
                    return a.isDirectory ? -1 : 1;
                }
                return a.name.localeCompare(b.name);
            });

        for (const item of sortedItems) {
            if (item.isDirectory) {
                // book, node_modules, .git などは除外
                if (!['book', 'node_modules', '.git'].includes(item.name)) {
                    const dirName = item.name.replace(/-/g, ' ').replace(/^\d+\s*/, '');
                    const line = `${'  '.repeat(depth)}- [${dirName}]()`
                    if (isApi) {
                        apiContent.push(line);
                        processDirectory(item.path, depth + 1, true);
                    } else if (item.name === 'api') {
                        // apiディレクトリの処理を後回しにする
                        processDirectory(item.path, depth + 1, true);
                    } else {
                        summary.push(line);
                        processDirectory(item.path, depth + 1, false);
                    }
                }
            } else if (item.name.endsWith('.md') && item.name !== 'SUMMARY.md') {
                // Markdownファイルの処理
                const relativePath = path.relative(docsDir, item.path).replace(/\\/g, '/');
                const title = path.basename(item.name, '.md').replace(/-/g, ' ');
                const line = `${'  '.repeat(depth)}- [${title}](${relativePath})`;
                if (isApi) {
                    apiContent.push(line);
                } else {
                    summary.push(line);
                }
            }
        }
    }

    processDirectory(docsDir);

    // apiコンテンツを最後に追加
    if (apiContent.length > 0) {
        summary.push(...apiContent);
    }

    // SUMMARY.mdを書き出し
    fs.writeFileSync(path.join(docsDir, 'SUMMARY.md'), summary.join('\n'));
}

generateSummary(); 