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
Es un videojuego de supervivencia en 2D donde un astronauta debe aterrizar forzosamente en un planeta hostil, recolectar recursos y defenderse de oleadas de ataques para reparar su nave.

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

* **Movimiento:** Usa `WASD` para desplazarte por el planeta. El personaje tiene aceleración y fricción, por lo que el movimiento es fluido.
* **Ataque:** Presiona `Espacio` para atacar con tu arma de corto rango. No puedes moverte mientras atacas.
* **Farmear:** Presiona `Q` cerca de recursos del entorno para recolectarlos. Son necesarios para reparar la nave.
* **Interactuar:** Presiona `E` para interactuar con objetos del escenario, como la nave o ítems recogibles.