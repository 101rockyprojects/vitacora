export function renderMd(md: string): string {
    return md
      .replace(/^[\u200B\u200C\u200D\u200E\u200F\uFEFF]/,"")
      .replace(/^### (.+)$/gm, '<h3>$1</h3>')
      .replace(/^## (.+)$/gm, '<h2>$1</h2>')
      .replace(/^# (.+)$/gm, '<h1>$1</h1>')
      .replace(/^(---|\*\*\*|___)$/gm, '<hr/>')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      .replace(/`(.+?)`/g, '<code>$1</code>')
      .replace(
        /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
      )
      .replace(/^(\s*)(\d+)\.\s+(.+)$/gm, (_, spaces, num, content) => {
        const indent = (spaces.length + 1) * (spaces.length > 0 ? 0.5 : 1);
        return `<li style="margin-left:${indent}px">${num}. ${content}</li>`;
      })
      .replace(/^(\s*)- (.+)$/gm, (_, spaces, content) => {
        const indent = (spaces.length + 1) * (spaces.length > 0 ? 0.5 : 1);
        return `<li style="margin-left:${indent}rem">${content}</li>`;
      })
      .replace(/(<li>.*<\/li>(?:\n<li>.*<\/li>)*)/g, '<ul>$1</ul>\n')
      .replace(/\n/g, '<br/>')
      .replace(/\n\n/g, '');
}

export function formatLinks(md: string): string {
  return md.replace(
    /(?<!\()https?:\/\/(?:[^\/.\s]+\.)?([^\/.\s]+)([^\s]*)/g,
    '[Ver en $1](https://$1$2)'
  );
}
