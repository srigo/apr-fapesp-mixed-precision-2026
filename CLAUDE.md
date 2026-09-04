# CLAUDE.md

Instruções de projeto para o Claude Code neste repositório.

## Sobre o projeto

Proposta de projeto de pesquisa "Precision-AMR" (mixed-precision + AMR para
RTM/FWI baseada em EDPs). O texto-fonte original está em
[doc/Precision-AMR_Proposal.docx](doc/Precision-AMR_Proposal.docx). A partir
dele foram criadas duas versões em LaTeX, mantidas em paralelo:

- [src/pt/mixed-precision-amr-pt.tex](src/pt/mixed-precision-amr-pt.tex) —
  versão em português do Brasil.
- [src/en/mixed-precision-amr-en.tex](src/en/mixed-precision-amr-en.tex) —
  versão em inglês.

Cada versão tem seu próprio arquivo `.bib` (`mixed-precision-amr-pt.bib` /
`mixed-precision-amr-en.bib`) com as mesmas referências; apenas os campos
`note`/`howpublished` variam de idioma.

## Backups congelados — não alterar

O usuário criou cópias de backup do estado da proposta anterior à
reestruturação para o roteiro FAPESP (a formatação de fonte/espaçamento/
margens já havia sido aplicada nesse estado):

- [src/pt/precision-amr-backup-pt.tex](src/pt/precision-amr-backup-pt.tex)
- [src/en/precision-amr-backup-en.tex](src/en/precision-amr-backup-en.tex)

**Esses dois arquivos são congelados e não devem ser editados, traduzidos,
recompilados ou apagados daqui em diante**, por nenhum motivo — nem para
manter equivalência com as versões principais, nem em correções mecânicas.
Eles existem apenas como referência histórica da estrutura de seções
anterior (Abstract / Computational Platforms / Dataset and Model /
Introduction / Methods / Evaluation / Expected Results / Project Support
Details / Resource Request), para consulta caso seja preciso comparar ou
recuperar conteúdo durante a reestruturação. Ficam fora do fluxo de
equivalência `pt`↔`en`, fora do ciclo de aprovação, e fora dos comandos de
build/limpeza descritos em "Compilação" — não têm `.bib` próprio nem
precisam compilar isoladamente. Se o usuário pedir alguma mudança que
tocaria nesses arquivos, confirmar antes de prosseguir, já que a instrução
é para mantê-los intocados.

## Destino da proposta: Auxílio à Pesquisa Regular (APR) da FAPESP

Esta proposta será submetida como um pedido de **Auxílio à Pesquisa Regular
(APR)** da FAPESP. As modificações pedidas ao texto a partir de agora têm
como objetivo adequá-lo ao formato exigido pela FAPESP para esse tipo de
auxílio. As regras oficiais completas estão em:

- Formatação do texto do projeto:
  https://fapesp.br/10408/roteiro-para-formatacao-do-projeto-de-pesquisa-auxilio-a-pesquisa-regular
- Regras gerais do APR:
  https://fapesp.br/apr

Ambas devem ser (re)consultadas via `WebFetch` sempre que houver dúvida ou
antes de confirmar conformidade em um ponto específico, pois a FAPESP pode
atualizar essas páginas. **Qualquer sugestão de conteúdo, estrutura ou
formatação que viole alguma regra de submissão do APR deve ser apontada
explicitamente ao usuário** — nunca aplicada silenciosamente nem descartada
sem comentário.

### Resumo das regras de formatação do texto (roteiro FAPESP)

- **Fonte:** Calibri ou Arial, tamanho 12.
- **Espaçamento entre linhas:** 1,5.
- **Margens:** 3 cm à esquerda, 1,5 cm à direita.
- **Figuras e tabelas:** precisam de legenda explicativa e numeração para
  referência no texto.
- **Extensão máxima:** 25 páginas, excluindo folhas de rosto, bibliografia e
  planilhas orçamentárias.
- **Estrutura obrigatória, nesta ordem:**
  0. **Folhas de rosto** (2 páginas): uma em português e uma em inglês, com
     título do projeto, nome do Pesquisador Responsável, Instituição Sede e
     um resumo (abstract) de até 20 linhas.
  1. **Caracterização do Problema:** o problema de pesquisa, sua
     importância e contribuição potencial para a área, com citações
     relevantes.
  2. **Resultados Esperados:** o que será criado/produzido pelo projeto.
  3. **Desafios Científicos/Tecnológicos e Métodos:** os desafios,
     descrição dos métodos para superá-los, com referências que comprovem
     que o problema segue em aberto ou mal resolvido.
  4. **Cronograma de Execução:** data de conclusão do projeto e eventos
     marcantes (*milestones*) que meçam o progresso.
  5. **Descrição das Atividades da Equipe:** descrição breve (até um
     parágrafo cada) das atividades de Pesquisadores Associados,
     bolsistas e alunos não financiados.
  6. **Divulgação e Avaliação:** como os resultados serão avaliados e
     comunicados.
  7. **Outros Apoios:** financiamentos, bens ou serviços adicionais (exceto
     infraestrutura institucional já disponível).
  8. **Bibliografia:** todas as referências citadas.
  9. **Planilhas Orçamentárias (SAGe):** recursos solicitados à FAPESP,
     preenchidos na aba "R$/US$" do sistema SAGe.

Isso é estruturalmente diferente da organização atual dos `.tex`
(Abstract / Computational Platforms / Dataset and Model / Introduction /
Methods / Evaluation / Expected Results / Project Support Details / Resource
Request). Ao adequar o texto ao roteiro do APR, mapear o conteúdo existente
para as novas seções obrigatórias — sem simplesmente renomear títulos — e
sinalizar ao usuário qualquer conteúdo atual que não se encaixe claramente
em nenhuma seção do roteiro.

### Resumo das regras gerais do APR

- **Elegibilidade do Pesquisador Responsável:** doutorado (ou equivalente),
  vínculo com instituição de pesquisa do estado de São Paulo, experiência
  internacional de pós-doutorado ou participação ativa em redes
  colaborativas internacionais, adimplência com a FAPESP.
- **Duração:** até 36 meses, prorrogável por até 6 meses em condições
  excepcionais.
- **Submissão:** fluxo contínuo, a qualquer época, exclusivamente via
  Sistema de Apoio à Gestão (SAGe) — análise leva, em média, ~75 dias.
- **Orçamento:** máximo de R$ 600 mil (excluindo Reserva Técnica), com
  equipamentos individuais limitados a R$ 150 mil por item; valores acima
  do teto só em condições excepcionais e justificadas.
- **Itens financiáveis:** material permanente e de consumo, serviços de
  terceiros técnicos, transporte/diárias, bolsas de pesquisa, Reserva
  Técnica.
- **Itens não financiáveis:** salários, serviços administrativos,
  construções civis que aumentem área construída, despesas fora da
  vigência do projeto.
- **Documentos exigidos além do texto do projeto:** súmula curricular do
  Pesquisador Responsável e Associados; resultados de auxílios anteriores
  (últimos 5 anos); planos de atividades por bolsa solicitada; orçamentos
  de fornecedores (3 orçamentos se o valor exceder dez salários mínimos);
  plano de gestão de dados (até 2 páginas); manifestação do dirigente da
  instituição sede; informações de infraestrutura institucional (Anexo
  II).
- **Restrições importantes:** no máximo um APR vigente simultaneamente por
  pesquisador (salvo exceção justificada); qualquer modificação no projeto
  aprovado exige consentimento prévio da FAPESP; obrigatoriedade de
  consultar a FAPESP antes de aceitar financiamento complementar.

A pasta `doc/` guarda o texto original em docx solicitado ao usuário; o
plano de gestão de dados, a súmula curricular, as folhas de rosto e as
planilhas SAGe são artefatos separados do texto do projeto propriamente
dito — não fazem parte dos arquivos em `src/pt/` e `src/en/` a menos que o
usuário peça explicitamente para criá-los.

## Regra central: português é a versão principal

**A versão em português (`src/pt/`) é a fonte de verdade do texto.** Todo
conteúdo novo ou alteração de conteúdo deve seguir este fluxo:

1. **Propor a mudança na versão em português primeiro.** Editar
   `src/pt/mixed-precision-amr-pt.tex` (e `.bib`, se houver novas
   referências) e compilar para gerar um PDF de validação.
2. **Aguardar validação do usuário** sobre a mudança em português antes de
   tocar na versão em inglês. Não presumir aprovação silenciosa — se o
   usuário não confirmou explicitamente, tratar a mudança em português como
   ainda não aprovada e não propagá-la.
3. **Somente depois de aprovada**, aplicar a mudança equivalente em
   `src/en/mixed-precision-amr-en.tex` (e `.bib`), traduzindo com o mesmo
   nível de precisão técnica usado na tradução original.
4. **Recompilar ambas as versões** e confirmar que os dois PDFs compilam sem
   erro (nem citações/referências indefinidas) antes de considerar a tarefa
   concluída.

Exceções: correções puramente mecânicas que não mudam o conteúdo técnico
(erro de digitação, formatação LaTeX, ajuste de quebra de linha) podem ser
replicadas diretamente nas duas versões, sem passar pelo ciclo de aprovação
— mas ainda assim devem manter os dois textos equivalentes.

## Manter os dois textos equivalentes

- Estrutura de seções, subseções, itens de lista, tabelas e ordem do
  conteúdo devem corresponder um a um entre `pt` e `en`.
- Números, siglas, nomes próprios (RTM, FWI, AMR, PML, PSNR, SSIM, GPUZIP,
  Santos Dumont, RTX PRO 6000, GH200, MI300A etc.), unidades e valores
  numéricos devem ser idênticos nas duas versões.
- Termos técnicos em inglês sem tradução consagrada em português podem
  aparecer em itálico na versão `pt` (como já ocorre em `tile`, `tiling`,
  `roofline`, `lossy compression`, `ground truth`) — não é necessário
  "aportuguesar" à força.
- Referências bibliográficas (`.bib`) devem ter as mesmas chaves de citação
  (`\cite{...}`) e os mesmos entries nas duas pastas; ao adicionar uma
  referência nova, criar a entrada em ambos os `.bib` files.
- Se uma mudança for feita diretamente em `en` por engano ou pedido
  explícito do usuário, sinalizar que ela precisa ser retro-portada para
  `pt` para não quebrar a equivalência — nunca deixar `en` divergir
  silenciosamente do `pt`.

## Compilação

Os dois documentos usam a fonte Arial via `fontspec`, o que exige **XeLaTeX**
(não `pdflatex`) — a diretiva `% !TEX program = xelatex` está na primeira
linha de cada `.tex` para editores que a reconhecem. Cada pasta (`src/pt/`,
`src/en/`) é buildada independentemente com `latexmk`:

```bash
cd src/pt && latexmk -xelatex -interaction=nonstopmode -halt-on-error mixed-precision-amr-pt.tex
cd src/en && latexmk -xelatex -interaction=nonstopmode -halt-on-error mixed-precision-amr-en.tex
```

Isso roda `xelatex → bibtex → xelatex → xelatex` automaticamente. Após
compilar, checar o `.log` por citações/referências indefinidas:

```bash
grep -iE "undefined|LaTeX Warning: Citation|LaTeX Warning: Reference" *.log
```

Ao final, limpar os artefatos de build (mantendo o `.pdf`):

```bash
latexmk -c mixed-precision-amr-<pt|en>.tex
rm -f mixed-precision-amr-<pt|en>.bbl mixed-precision-amr-<pt|en>.xdv
```

Os arquivos temporários (`.aux`, `.bbl`, `.blg`, `.fdb_latexmk`, `.fls`,
`.log`, `.out`, `.synctex.gz`, `.xdv`) já estão listados no `.gitignore` de
cada pasta e não devem ser versionados.

### Formatação aplicada (padrão FAPESP APR)

Ambos os `.tex` já seguem o roteiro de formatação da FAPESP na base do
documento: `\setmainfont{Arial}` a 12pt (`\documentclass[12pt,...]`),
`\onehalfspacing` (pacote `setspace`) e margens via `geometry`
(`left=3cm,right=1.5cm,top=2.5cm,bottom=2.5cm` — a FAPESP só especifica as
margens esquerda e direita; topo/base ficam em 2.5cm por padrão razoável).
Não desfazer esses ajustes ao editar o preâmbulo; qualquer alteração de
fonte/espaçamento/margem deve ser justificada e apontada ao usuário, pois
mexe diretamente em requisito de submissão do APR.

## Entrega ao usuário

Depois de compilar, enviar o PDF atualizado ao usuário (via `SendUserFile`)
para que a mudança possa ser revisada visualmente, especialmente no ciclo de
aprovação da versão em português.
