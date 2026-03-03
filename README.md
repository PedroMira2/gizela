# pilatGZ - Pilates, Yoga & Bem-Estar

![pilatGZ](public/images/hero-main.jpg)

Site oficial da pilatGZ - Academia de Pilates, Yoga e Bem-Estar localizada em Aveiro, Portugal.

## 🌐 Demo

[Ver site ao vivo](https://pilatgz.netlify.app)

## ✨ Funcionalidades

- **Design Moderno & Elegante** - Interface minimalista com animações suaves
- **Totalmente Responsivo** - Funciona perfeitamente em desktop, tablet e mobile
- **Seções Completas:**
  - Hero com animações GSAP
  - Sobre a academia
  - Modalidades (Pilates, Yoga Flow, Yoga Restore, Barre)
  - Testemunhos de alunos
  - FAQ interativo
  - Planos e preços
  - Equipa de instrutores
  - Blog
  - Formulário de contacto

## 🛠️ Tecnologias

- **React 19** + **TypeScript**
- **Vite** - Build tool ultrarrápido
- **Tailwind CSS** - Estilização utilitária
- **GSAP + ScrollTrigger** - Animações avançadas
- **shadcn/ui** - Componentes UI
- **Lucide React** - Ícones

## 🚀 Deploy na Netlify

### Opção 1: Deploy Automático (Recomendado)

1. Faça fork deste repositório para a sua conta GitHub
2. Acesse [Netlify](https://netlify.com) e faça login
3. Clique em "Add new site" → "Import an existing project"
4. Selecione o repositório GitHub
5. Configure:
   - **Build command:** `npm run build`
   - **Publish directory:** `dist`
6. Clique em "Deploy site"

### Opção 2: Deploy Manual

```bash
# Instalar dependências
npm install

# Build de produção
npm run build

# Fazer upload da pasta 'dist' na Netlify
```

## 📁 Estrutura do Projeto

```
├── public/
│   └── images/          # Imagens do site
├── src/
│   ├── components/      # Componentes reutilizáveis
│   ├── sections/        # Seções da página
│   ├── config.ts        # Configuração de conteúdo
│   └── App.tsx          # Componente principal
├── dist/                # Build de produção
├── netlify.toml         # Configuração Netlify
└── README.md
```

## 🎨 Personalização

Edite o arquivo `src/config.ts` para personalizar:
- Textos e títulos
- Imagens
- Links de navegação
- Informações de contacto
- Planos e preços

## 📝 Licença

Este projeto é privado e destinado exclusivamente à pilatGZ.

---

**pilatGZ** - Transforme o seu corpo e a sua mente  
📍 Aveiro, Portugal
