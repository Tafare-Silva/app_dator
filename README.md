# Restaurante App — Flutter

App Android para controle de mesas e comandas, integrado ao backend FastAPI.

## Estrutura

```
lib/
├── core/
│   ├── app_config.dart       # URL da API e constantes
│   └── app_theme.dart        # Cores e tema visual
├── models/
│   └── models.dart           # Todos os models de dados
├── services/
│   ├── api_client.dart       # Dio + interceptor JWT
│   └── services.dart         # AuthService, MesaService, ItemMesaService, ProdutoService
├── screens/
│   ├── login/
│   │   ├── auth_provider.dart   # Estado de autenticação (Provider)
│   │   └── login_screen.dart    # Tela de login
│   ├── mesas/
│   │   └── mesas_screen.dart    # Grid de mesas
│   ├── mesa_detalhe/
│   │   └── mesa_detalhe_screen.dart  # Itens da comanda
│   ├── produtos/
│   │   └── busca_produto_screen.dart # Busca e adição de produtos
│   └── conta/
│       └── conta_screen.dart    # Resumo e fechamento de conta
└── main.dart
```

## Configuração

### 1. Ajuste a URL da API

Edite `lib/core/app_config.dart`:

```dart
static const String baseUrl = 'http://SEU_IP:8000/api/v1';
```

> **Dica**: Para descobrir o IP da sua máquina na rede local:
> - Windows: `ipconfig` no CMD
> - Linux/Mac: `ifconfig` ou `ip addr`

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Rode o app

```bash
flutter run
```

## Dependências principais

| Pacote | Uso |
|--------|-----|
| `dio` | Cliente HTTP |
| `provider` | Gerenciamento de estado |
| `flutter_secure_storage` | Armazenamento seguro do token JWT |
| `google_fonts` | Tipografia (Inter) |
| `intl` | Formatação de moeda e datas |

## Próximos passos

- [ ] Integrar impressão térmica (`flutter_thermal_printer` / `esc_pos_bluetooth`)
- [ ] Implementar fechamento de conta → geração de pedido de venda
- [ ] Persistência do login entre sessões (token salvo no SecureStorage já está pronto)
- [ ] Modo offline básico com cache local
