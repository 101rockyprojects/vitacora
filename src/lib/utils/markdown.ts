export function renderMd(md: string): string {
  // Process first code blocks
  let codeblockMd: string[] = [];
  md = md.replace(/```([\s\S]*?)```/g, (match, content) => {
    let idx = codeblockMd.length;
    codeblockMd.push(`<pre>${escapeHtml(content)}</pre>`);
    return `__CODEBLOCK_${idx}__`;
  });

  // Process inline code formatting
  let inlineCodes: string[] = [];
  md = md.replace(/`([^`]+)`/g, (match, content) => {
    let idx = inlineCodes.length;
    inlineCodes.push(`<code>${escapeHtml(content)}</code>`);
    return `__INLINECODE_${idx}__`;
  });

  const lines = md.split('\n');
  const processedLines: string[] = [];
  
  for (const line of lines) {
    let processedLine = line;
    if (processedLine.match(/^### /)) {
      processedLine = processedLine.replace(/^### (.+)$/, '<h3>$1</h3>');
    } else if (processedLine.match(/^## /)) {
      processedLine = processedLine.replace(/^## (.+)$/, '<h2>$1</h2>');
    } else if (processedLine.match(/^# /)) {
      processedLine = processedLine.replace(/^# (.+)$/, '<h1>$1</h1>');
    }
    else if (processedLine.match(/^(---|\*\*\*|___)$/)) {
      processedLine = '<hr/>';
    }
    else if (processedLine.match(/^> /)) {
      processedLine = processedLine.replace(/^> (.+)/, '<blockquote>$1</blockquote>');
    }
    else {
      processedLine = processedLine.replace(
        /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
      );
      processedLine = processedLine.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    }
    
    processedLines.push(processedLine);
  }
  
  let result = processedLines.join('\n');
  result = result.replace(/^(\s*)(\d+)\.\s+(.+)$/gm, (_, spaces, num, content) => {
    const indent = (spaces.length + 1) * (spaces.length > 0 ? 0.5 : 1);
    return `<li style="margin-left:${indent}rem">${num}. ${content}</li>`;
  });
  
  result = result.replace(/^(\s*)- (.+)$/gm, (_, spaces, content) => {
    const indent = (spaces.length + 1) * (spaces.length > 0 ? 0.5 : 1);
    return `<li style="margin-left:${indent}rem">${content}</li>`;
  });
  result = result.replace(/(<li.*<\/li>(?:\n<li.*<\/li>)*)/g, '<ul>$1</ul>');
  result = result.replace(/__INLINECODE_(\d+)__/g, (_, idx) => inlineCodes[idx]);
  result = result.replace(/__CODEBLOCK_(\d+)__/g, (_, idx) => codeblockMd[idx]);
  
  // Line breaks (except <pre> or <code>)
  const preservedBlocks: string[] = [];
  result = result.replace(/(<(?:pre|code)[^>]*>[\s\S]*?<\/\1>)/g, (match) => {
    preservedBlocks.push(match);
    return `__PRESERVED_${preservedBlocks.length - 1}__`;
  });
  
  result = result.replace(/\n/g, '<br/>');
  // Restore preserved blocks of code
  result = result.replace(/__PRESERVED_(\d+)__/g, (_, idx) => preservedBlocks[idx]);
  
  return result;
}

// Función auxiliar para escapar HTML
function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function getMarkdownHelp(): string {
  return `# ¿Qué es Markdown?
        
Markdown es un lenguaje de marcado ligero que puedes usar para dar formato a tu texto. Aquí tienes una guía rápida de sintaxis:

## Encabezados
Usa el símbolo # para crear encabezados. Más símbolos indican un nivel de encabezado más bajo.
\`\`\`
# Encabezado 1
## Encabezado 2
### Encabezado 3
\`\`\`
## Formato de texto
- **Negrita**: \`**texto**\`
- *Cursiva*: \`*texto*\`
- ~~Tachado~~: \`~~texto~~\`
## Listas
- Listas no ordenadas: usa \`-\` o \`*\`
- Listas ordenadas: usa números seguidos de un punto (\`1.\`, \`2.\`, etc.)
\`\`\`
- Elemento 1
- Elemento 2
1. Primer paso
2. Segundo paso
\`\`\`
## Enlaces
Crea enlaces usando corchetes para el texto y paréntesis para la URL.
\`\`\`
[Google](https://www.google.com)
\`\`\`
Se ve así: [Google](https://www.google.com)

## Código
Para código en línea, usa una sola tilde invertida. Para bloques de código, usa tres tildes invertidas:

\`Código en línea\`

\`\`\`
Bloque de código
\`\`\`

## Para saber más
Puedes consultar la documentación oficial de Markdown para más detalles y características avanzadas: [Markdown Guide](https://www.markdownguide.org/)

> Aprovecha el poder de Markdown para organizarte y dar formato a tus ideas con solo texto.
    `;
}

export function formatLinks(md: string): string {
  return md.replace(
    /(?<!\()https?:\/\/(?:[^\/.\s]+\.)?([^\/.\s]+)([^\s]*)/g,
    '[Ver en $1](https://$1$2)'
  );
}
