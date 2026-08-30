# 🚀 Espaço Infinito — Protótipo Passo 1

**4X espacial com simulação histórica procedural**  
Referências: Dwarf Fortress (Legends Mode) × Stellaris

---

## Como Rodar

### Pré-requisitos
- [Godot 4.3+](https://godotengine.org/download/) (versão Standard ou .NET — ambas funcionam)

### Passos
1. Abra o Godot Engine
2. Clique em **"Import"** ou **"Importar"**
3. Navegue até esta pasta e selecione o arquivo `project.godot`
4. Clique em **"Import & Edit"**
5. Pressione **F5** (ou o botão ▶ Play) para rodar

---

## O que está implementado (Passo 1 + 2)

| Feature | Status |
|---------|--------|
| Gerador de galáxia procedural (seed reproduzível) | ✅ |
| Distribuição espiral orgânica (200-400 sistemas) | ✅ |
| Tipos de estrela com cores próprias | ✅ |
| Planetas procedurais por sistema | ✅ |
| Conexões de hiperespaço entre sistemas próximos | ✅ |
| Câmera com zoom suave pelo scroll do mouse | ✅ |
| Pan com botão direito/médio do mouse | ✅ |
| LOD (labels surgem no zoom suficiente) | ✅ |
| Fundo estrelado com parallax leve | ✅ |
| Hover e seleção de sistemas (anel visual) | ✅ |
| Painel de informações do sistema | ✅ |
| Foco automático no sistema natal | ✅ |
| Gerador de nomes procedural (fonético, sem IA) | ✅ |

---

## Controles

| Ação | Controle |
|------|----------|
| Zoom in/out | Scroll do mouse |
| Mover câmera | Botão direito + arrastar |
| Selecionar sistema | Clique esquerdo |
| Fechar painel de info | Botão × no painel |

---

## Mudar a Seed

Em `scenes/Main.tscn`, ou diretamente no Inspetor do Godot com o nó `Main` selecionado:
- Propriedade `Universe Seed` → mude o número → gera uma galáxia completamente diferente

---

## Estrutura de Arquivos

```
Espaço Infinito/
├── project.godot              # Configuração do projeto Godot
├── icon.svg                   # Ícone do jogo
├── scenes/
│   └── Main.tscn              # Cena principal
└── scripts/
    ├── Main.gd                # Orquestrador principal
    ├── GalaxyGenerator.gd     # Motor de geração da galáxia (headless)
    ├── GalaxyRenderer.gd      # Renderização 2D da galáxia
    ├── StarSystem.gd          # Estrutura de dados de um sistema estelar
    ├── NameGenerator.gd       # Gerador de nomes fonéticos (sem IA)
    ├── CameraController.gd    # Câmera com zoom centrado no mouse
    ├── StarfieldBackground.gd # Fundo estrelado com parallax
    └── SystemInfoPanel.gd     # Painel de UI ao clicar num sistema
```

---

## Próximos Passos

- **Passo 3**: Motor de geração de história (`HistoryEngine.gd`) — civilizações nascem, guerreiam, colapsam em segundos
- **Passo 4**: Tela de loading que narra a história enquanto gera
- **Passo 5**: Naves (setas geométricas) se movendo entre sistemas
- **Passo 6**: Clique no sistema mostra mais detalhes históricos
