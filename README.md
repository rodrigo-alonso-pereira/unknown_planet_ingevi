# Unknown Planet - Supervivencia Espacial

Este proyecto es parte del curso **INGENIERÍA DE VIDEOJUEGOS: FUNDAMENTOS Y APLICACIONES INTERACTIVAS**, correspondiente al 1er Semestre de 2026.

## 🚀 Información del Equipo
* **Nombre del Equipo:** Team Core Gaming
* **Integrantes:**
    * Patricio Neira
    * Rodrigo Pereira
    * Joaquín Pozo

## 🎮 Nombre del Proyecto
**Unknown Planet**
Es un videojuego de supervivencia y exploración en 2D. Un astronauta debe aterrizar forzosamente en un planeta hostil, abriéndose paso a través de diferentes biomas, derrotando enemigos (Slimes), recolectando recursos y sobreviviendo para encontrar la salida y lograr escapar.

## 🛠️ Motor Utilizado
* **Godot Engine 4.6** (Versión Standard / GDScript)

## 📂 Instrucciones para Abrir el Proyecto

Siga estos pasos para clonar y ejecutar el prototipo correctamente:

1.  **Clonar el Repositorio:**
    Abra una terminal y ejecute el siguiente comando:
    ```bash
    git clone https://github.com/rodrigo-alonso-pereira/unknown_planet_ingevi.git
    ```

2.  **Descargar Godot:**
    Asegúrese de tener instalado **Godot Engine 4.6** (disponible en [godotengine.org](https://godotengine.org/)).

3.  **Importar el Proyecto:**
    * Abra el **Godot Project Manager**.
    * Haga clic en el botón **Import** a la derecha.
    * Navegue hasta la carpeta clonada y seleccione el archivo `project.godot`.
    * Haga clic en **Import & Edit**.

4.  **Ejecutar la Escena Base:**
    * Una vez dentro del editor, localice la escena principal en la ruta `res://scenes/survival_level.tscn`.
    * Presione **F5** (o el botón Play en la esquina superior derecha) para iniciar la simulación.

---
## 🕹️ Instrucciones para Jugar

El objetivo es sobrevivir en un planeta hostil: recolectar recursos farmeando, repara tu nave interactuando con ella y defiéndete de los enemigos con tu ataque de corto rango.
El objetivo principal es sobrevivir a lo largo de 3 niveles distintos (Planeta Desconocido, Catacumbas y Tormenta de Hielo), abriéndote paso entre las oleadas de enemigos, farmear los recursos para reparar la nave y alcanzar el punto de extracción (Salida).

### Controles

| Acción | Teclado | Gamepad |
|---|---|---|
| Mover arriba | `W` | Joypad axis 1 − |
| Mover abajo | `S` | Joypad axis 1 + |
| Mover izquierda | `A` | Joypad axis 0 − |
| Mover derecha | `D` | Joypad axis 0 + |
| Ataque de corto rango | `Espacio` | Button 1 |
| Interactuar | `E` | Button 2 |
| Farmear | `Q` | Button 3 |

### Mecánicas principales
* **Exploración y Progresión:** El juego cuenta con un sistema de transición de niveles. Debes explorar el mapa hasta encontrar la zona de salida para avanzar al siguiente bioma.
* **Sistema de Combate y Salud:** El jugador cuenta con 5 corazones (100 HP). El contacto directo o los ataques de los Slimes reducirán la vida. Al llegar a 0, el juego termina (Game Over).
* **Ataque Melee:** Presiona `Espacio` para usar tu espada. Eliminar enemigos actualizará tu contador de bajas (Kills) en la esquina superior derecha. 
* **Farmear e Interactuar:** Usa `Q` y `E` para recolectar recursos en el entorno y manipular objetos clave del escenario (como la nave espacial).
* **Interfaz Dinámica (HUD):** El juego presenta un HUD completo que rastrea la vida en tiempo real, el conteo de enemigos derrotados, cantidad de recursos recolectados y menús interactivos para reiniciar la partida o salir tras la victoria o la muerte.