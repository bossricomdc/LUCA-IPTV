# LUCA IPTV — iOS

Port inicial do projeto Android para iOS usando SwiftUI e AVPlayer.

## Incluído
- Login no painel LUCA IPTV
- Persistência de sessão
- Obtenção automática das credenciais Xtream
- Categorias de filmes, séries e TV ao vivo
- Catálogo por categoria e busca local
- Séries com `get_series_info`, temporadas e episódios
- Reprodução com AVPlayer
- Logout

## Como abrir
Abra `LUCAIPTV.xcodeproj` no Xcode 16 ou superior.

Em **Signing & Capabilities**, selecione seu Team e ajuste o Bundle Identifier se necessário.

## Observações
- O projeto permite HTTP para compatibilidade com servidores Xtream legados.
- AVPlayer no iOS funciona melhor com HLS (`.m3u8`). Alguns servidores que entregam apenas MPEG-TS bruto (`.ts`) podem exigir uma URL HLS alternativa ou player como VLC/MobileVLCKit.
- Google Cast do Android não foi portado nesta primeira versão.
- Antes de distribuir na App Store, revise as regras de conteúdo/licenciamento aplicáveis ao serviço IPTV.
