;Implementacion de BLOKUS.


;Un estado en Blokus viene definido por una matriz que indica los bloque ocupados en el tablero principal y una tabla hash con una entrada por
; cada jugador. En cada entrada de la tabla hash se almacena la lista de piezas del jugador correspondiente. Cada pieza es representada por
; una matriz en la cual, a un bloque de la pieza le corresponde un 1 y a un hueco un 0. En la matriz que define el tablero, una casilla vacia es
; representada por un 0 y una casilla ocupada por un bloque es representado por el numero que identifica al jugador al que pertenece.

;Cada jugador dispone del mismo numero y tipo de piezas. Las piezas pueden girarse y reflejare y solo pueden colocarse de manera diagonal con
; respecto a las ya colocadas por parte del propio jugador (pueden ser contiguas a otras de otros jugadores pero siempre oblicua a alguna
; perteneciente al mismo). El estado inicial es el tablero vacío (toda casilla a 0) y las listas de piezas de cada jugador completas.

;Cada bloque de cada pieza equivale a 1 punto (todas las piezas de un jugador son 89 bloques), el jugador que coloca todas las piezas 
; suma 15 puntos adicionales. Ademas si la pieza de un bloque, I1, es la última en ser colocada, se suman 5 puntos mas para dicho jugador. 
; Inicialmente todos empiezan con 0 puntos y en total hay 356 puntos entre los 4 jugadores.

;Los posibles estados finales dependen de si algun jugador ha colocado todas sus fichas (ganador) o ningun jugador puede colocar ninguna
;ficha mas en el tablero (gana quien mas bloques haya colocado en el tablero).

;El juego tiene un maximo de 4 jugadores y un minimo de 2 y cada jugador comienza en una esquina del tablero.

;Los jugadores se identificaran con los numeros del 1 al 4. Eventualmente tienen asociado un color.

;Definicion de constantes.

(defconstant dim-tablero '(20 20))

;Datos de las piezas del juego.



(defconstant Z5 (make-array '(3 3) :initial-contents '((1 1 0) (0 1 0) (0 1 1)))) ;Piezas de 5 bloques.
(defconstant L5 (make-array '(4 2) :initial-contents '((1 0) (1 0) (1 0) (1 1))))
(defconstant Y5 (make-array '(4 2) :initial-contents '((1 0) (1 1) (1 0) (1 0))))
(defconstant N5 (make-array '(4 2) :initial-contents '((1 0) (1 0) (1 1) (0 1))))
(defconstant P5 (make-array '(3 2) :initial-contents '((1 1) (1 1) (1 0))))
(defconstant I5 (make-array '(5 1) :initial-contents '((1) (1) (1) (1) (1))))
(defconstant T5 (make-array '(3 3) :initial-contents '((1 1 1) (0 1 0) (0 1 0))))
(defconstant F5 (make-array '(3 3) :initial-contents '((0 1 1) (1 1 0) (0 1 0))))
(defconstant X5 (make-array '(3 3) :initial-contents '((0 1 0) (1 1 1) (0 1 0))))
(defconstant U5 (make-array '(2 3) :initial-contents '((1 0 1) (1 1 1))))
(defconstant V5 (make-array '(3 3) :initial-contents '((1 0 0) (1 0 0) (1 1 1))))
(defconstant W5 (make-array '(3 3) :initial-contents '((1 0 0) (1 1 0) (0 1 1))))

(defconstant Z4 (make-array '(2 3) :initial-contents '((1 1 0) (0 1 1)))) 		  ;Piezas de 4 bloques.
(defconstant O4 (make-array '(2 2) :initial-contents '((1 1) (1 1))))
(defconstant T4 (make-array '(2 3) :initial-contents '((1 1 1) (0 1 0))))
(defconstant L4 (make-array '(3 2) :initial-contents '((1 0) (1 0) (1 1))))
(defconstant I4 (make-array '(4 1) :initial-contents '((1) (1) (1) (1))))

(defconstant V3 (make-array '(2 2) :initial-contents '((1 0) (1 1))))			  ;Piezas de 3 bloques.
(defconstant I3 (make-array '(3 1) :initial-contents '((1) (1) (1))))

(defconstant I2 (make-array '(2 1) :initial-contents '((1) (1))))				  ;Piezas de 2 bloques.

(defconstant I1 (make-array '(1 1) :initial-contents '((1))))					  ;Pieza de 1 bloque.


(defconstant piezas (list Z5 L5 Y5 N5 P5 I5 T5 F5 X5 U5 V5 W5 Z4 O4 T4 L4 I4 V3 I3 I2 I1))

;Datos de los jugadores.

(defconstant color-jugador-1 'AZ)
(defconstant color-jugador-2 'VE)
(defconstant color-jugador-3 'AM)
(defconstant color-jugador-4 'RO)

;Estructura de datos para el estado del juego.

(defstruct estado
  (tablero (make-array dim-tablero))
  (jugadores (make-hash-table)))

;Definicion de variables.

(defvar *minimo-valor* 0)
(defvar *maximo-valor* 109)   ;89 bloques mas un maximo de 20 puntos adicionales.
(defvar *numero-jugadores* 4) ;Juego de 2 a 4 jugadores
(defvar *estado-inicial* (make-estado))

(defvar *rotaciones* '(rota90 rota180 rota270))
(defvar *pasa-turno* (make-array '(1 1) :initial-contents '((0)))) ;Pieza especial para pasar turno si el jugador no tiene movimientos validos
																   ; y el estado en el que se aplica no es un estado final.		

;Inicializacion.

(loop for j from 1 to *numero-jugadores*
	do (setf (gethash j (estado-jugadores *estado-inicial*)) piezas))
	
(defvar *maxima-suma* (+ (* 89 *numero-jugadores*) 20)) ; Maxima suma del vector de puntuaciones para la poda superficial.

;Segun lo expuesto en el recurso R4, si en el juego no se cumple la desigualdad (maxima-suma < 2 * maximo-valor) no se lleva a cabo la poda superficial
; y solo podría hacer por tanto, poda inmediata. 
;
;R4. Sturtevant, N., Korf, R.: On Pruning Techniques for Multi-Player Games. In: AAAI 2000, pp. 201-207 (2000).
;
;Para Blokus la desigualdad solo se cumple en el caso de 2 jugadores (198 < 218). Con 3 jugadores (287 < 218) y 4 jugadores (376 < 218).

;Funciones de acceso.

;Un nodo viene dado por una lista con el estado (estructura estado) y un numero que indica el turno

(defun estado (nodo)
  "devuelve el estado del juego en el nodo dado"
  (first nodo)
)

(defun turno (nodo)
  "devuelve el identificador del jugador al que le toca mover"
  (second nodo)
)

;Un movimiento viene dado por una lista con una pieza (con una orientacion fijada), una posicion (tx,ty) del tablero, el identificador del jugador 
; que lo realiza y un valor que determina si se trata de un movimiento inicial. El identificador del jugador sirve para que al aplicar el movimiento 
; los bloques queden identificados como suyos.

(defun movimiento-pieza (movimiento)
  "devuelve la pieza asociada el movimiento" ;En este punto la pieza tiene una orientacion fija.
  (first movimiento)
)

(defun movimiento-posicion (movimiento)
  "devuelve la posicion del tablero asociada al movimiento" ;La posicion sobre la que se coloca la pieza.
  (second movimiento)
)

(defun movimiento-jugador (movimiento)
  "devuelve el jugador asociado al movimiento" ;Necesario para identificar los bloques en el tablero.
  (third movimiento)
)

(defun movimiento-inicial (movimiento)
  "devuelve un valor booleano que determina si se trata del movimiento inicial del jugador"
  (fourth movimiento)
)

;Funciones para la representación del juego

(defun es-estado-final (estado-actual)
  "determina si el estado dado es un estado final del juego"
  (let ((tablero (estado-tablero estado-actual))
		(ftablero (first dim-tablero)) (ctablero (second dim-tablero)))
		
	(loop for jugador from 1 to *numero-jugadores* ;Comprueba si hay algun jugador que haya usado todas sus piezas.
		if (eq (gethash jugador (estado-jugadores estado-actual)) nil)
		    do (return-from es-estado-final t))
			
	(loop for jugador from 1 to *numero-jugadores* ;Comprueba que ningun jugador tiene movimientos validos.
			if (= (length (gethash jugador (estado-jugadores estado-actual))) 21) ;Si tiene todas las piezas puede realizar el movimiento inicial.
			    do (return-from es-estado-final nil)
			   
			else ;El jugador ya ha realizado el movimiento inicial.	
				do (loop for pieza in (gethash jugador (estado-jugadores estado-actual))
					   do (loop for i from 1 to ftablero
						      do (loop for j from 1 to ctablero						
									 do (if (movimiento-valido tablero pieza (list i j) jugador nil)
											   (return-from es-estado-final nil)
											   
											   (progn (if (not (equalp pieza (refleja pieza)))
														  (if (movimiento-valido tablero (refleja pieza) (list i j) jugador nil)
															  (return-from es-estado-final nil))
															
														  (loop for rotacion in *rotaciones*
															if (and (not (equalp (funcall rotacion pieza) pieza))
																	(not (equalp (funcall rotacion pieza) (refleja pieza)))
																	(not (find (funcall rotacion pieza) procesadas :test #'equalp)))
																
															    do (if (movimiento-valido tablero (funcall rotacion pieza) (list i j) jugador nil)
																	   (return-from es-estado-final nil))
																
															collect (funcall rotacion pieza) into procesadas
															
															if (and (not (equalp (refleja (funcall rotacion pieza)) pieza))
																	(not (equalp (refleja (funcall rotacion pieza)) (refleja pieza)))
																	(not (find (refleja (funcall rotacion pieza)) procesadas :test #'equalp)))
																	
																do (if (movimiento-valido tablero (refleja (funcall rotacion pieza)) (list i j) jugador nil)
																       (return-from es-estado-final nil))
																	   
															collect (funcall rotacion pieza) into procesadas)))))))))
		
	t ;No hay ningun posible movimiento para ningun jugador.
)

(defun es-estado-ganador (estado-actual jugador)
  "determina si el estado dado es ganador para el jugador dado"
  (if (and (es-estado-final estado-actual) (eq (gethash jugador (estado-jugadores estado-actual)) nil))
	   t
	   nil)
)

(defun aplica-movimiento (movimiento estado-actual)
	"genera el estado sucesor para cada posible movimiento del juego"
	(let* ((pieza (movimiento-pieza movimiento))
		   (posicion (movimiento-posicion movimiento)) ;Posicion del tablero en la que se coloca la pieza.
		   (jugador (movimiento-jugador movimiento))   ;Identifica al jugador que hace el movimiento.
		   (inicial (movimiento-inicial movimiento))	 ;Indica si el movimiento es inicial.
		   (dim-pieza (array-dimensions pieza))
		   (fpieza (first dim-pieza)) (cpieza (second dim-pieza))
		   (tx (- (first posicion) 1)) (ty (- (second posicion) 1))
		   (estado-sucesor (copia-estado estado-actual))
		   (tablero (estado-tablero estado-sucesor)) 	 ;El tablero del estado sucesor es una copia del de estado actual.
		   (valido t))
		 
		 
		  (if (movimiento-valido tablero pieza posicion jugador inicial)
				   (loop for i from 0 to (- fpieza 1) ;Recorre la pieza asociada al movimiento.
					   do (loop for j from 0 to (- cpieza 1)
							  do (setf (aref tablero (+ i tx) (+ j ty)) (* jugador (aref pieza i j))))) ;El bloque lleva el identificador del jugador.
				  
					(setf valido nil))
	
		  (if (not valido)
			  (return-from aplica-movimiento 'no-aplicable)
			  (setf (gethash jugador (estado-jugadores estado-sucesor)) (remove pieza (gethash jugador (estado-jugadores estado-sucesor)))))
					   
					   
		estado-sucesor) ;Estado sucesor resultado de aplicar un movimiento valido.
)
    
(defun evaluacion-estatica (estado-actual turno-actual)
  "valora un nodo a partir del estado y el turno pertencientes al mismo"
  (loop for jugador from 1 to *numero-jugadores*
	collect (loop for pieza in piezas
				if (not (member pieza (gethash jugador (estado-jugadores estado-actual))))
					sum (puntuacion-pieza pieza) into resultado
					finally (if (es-estado-ganador estado-actual jugador)
								(return (+ resultado 15))
								(if (and (eq jugador turno-actual) (= resultado 88)) ; Solo le queda por poner la pieza I1 
																					 ;  que suma 5 puntos adicionales en ese caso.
									(return (+ resultado 5))
									(return resultado)))))
)

(defun movimientos (estado-actual turno-actual)
	"devuelve la lista de posibles movimientos dado un estado del juego y el turno de movimiento"
	(let ((piezas-jugador (gethash turno-actual (estado-jugadores estado-actual))))
		  
		 ;Se generaran los movimientos en funcion del numero del movimiento. Por ejemplo, para el primer movimiento solo tiene sentido
		 ; generar los movimientos posibles para la posicion inicial correspondiente al jugador. En los movimientos siguientes
		 ; solo se generan movimientos para una seccion del tablero dependiendo del jugador que mueve, evitando generar movimientos para 400 posiciones
		 ; en todos los casos, cuando puede que solo haya movimientos posibles en 100 posiciones del tablero. Una vez que se llega al sexto movimiento 
		 ; ya es necesario generar movimientos posibles para las 400 posiciones, pero en este caso el numero de piezas se ve reducido de manera que
		 ; se reducen igualmente el numero de movimientos posibles.
		 ;
		 ;El objetivo es mejorar, aunque sea levemente, el tiempo de ejecucion de los algoritmos.
		 
		 (case (length piezas-jugador) 
			
			(21 (loop for pieza in (genera-piezas piezas-jugador) ;Se trata del movimiento inicial (1).
				  collect (construye-movimiento pieza (posicion-inicial pieza turno-actual) turno-actual t)))
				  
				  
			(20 (let* ((tp (tablero-parcial turno-actual 2)) 	  ;Se trata del segundo movimiento (2).
					   (pinicial (first tp)) (longitud-tp (second tp)))
			
					  (loop for pieza in (genera-piezas piezas-jugador) 
						append (loop for i from (first pinicial) to (+ (first pinicial) (1- longitud-tp))
						  append (loop for j from (second pinicial) to (+ (second pinicial) (1- longitud-tp))
							collect (construye-movimiento pieza (list i j) turno-actual nil))))))
							
							
			(19 (let* ((tp (tablero-parcial turno-actual 3)) 	  ;Se trata del segundo movimiento (3).
					   (pinicial (first tp)) (longitud-tp (second tp)))
			
					  (loop for pieza in (genera-piezas piezas-jugador) 
						append (loop for i from (first pinicial) to (+ (first pinicial) (1- longitud-tp))
						  append (loop for j from (second pinicial) to (+ (second pinicial) (1- longitud-tp))
							collect (construye-movimiento pieza (list i j) turno-actual nil))))))
							
							
			(18 (let* ((tp (tablero-parcial turno-actual 4)) 	  ;Se trata del segundo movimiento (4).
					   (pinicial (first tp)) (longitud-tp (second tp)))
			
					  (loop for pieza in (genera-piezas piezas-jugador) 
						append (loop for i from (first pinicial) to (+ (first pinicial) (1- longitud-tp))
						  append (loop for j from (second pinicial) to (+ (second pinicial) (1- longitud-tp))
							collect (construye-movimiento pieza (list i j) turno-actual nil))))))
							
							
			(17 (let* ((tp (tablero-parcial turno-actual 5)) 	  ;Se trata del segundo movimiento (5).
					   (pinicial (first tp)) (longitud-tp (second tp)))
			
					  (loop for pieza in (genera-piezas piezas-jugador) 
						append (loop for i from (first pinicial) to (+ (first pinicial) (1- longitud-tp))
						  append (loop for j from (second pinicial) to (+ (second pinicial) (1- longitud-tp))
							collect (construye-movimiento pieza (list i j) turno-actual nil))))))
							
							
			(t (let* ((tp (tablero-parcial turno-actual 6)) 	  ;Se trata del sexto movimiento en adelante (6+).
					   (pinicial (first tp)) (longitud-tp (second tp)))
			
					  (loop for pieza in (genera-piezas piezas-jugador) 
						append (loop for i from (first pinicial) to longitud-tp
						  append (loop for j from (second pinicial) to longitud-tp
							collect (construye-movimiento pieza (list i j) turno-actual nil))))))))
						
)
					  					 
; Funciones auxiliares

(defun construye-nodo (estado-actual turno-actual)
	"devuelve un nodo del juego formado por el estado y el turno dado"
	(list estado-actual turno-actual)
)

(defun construye-movimiento (pieza posicion jugador inicial)
	"crea la lista de elementos que constituye un movimiento"
	(list pieza posicion jugador inicial)
)

(defun color-jugador (jugador)
	"devuelve el color asociado al jugador dado"
	(case jugador (1 color-jugador-1) (2 color-jugador-2) (3 color-jugador-3) (4 color-jugador-4))
)

(defun puntuacion-pieza (pieza)
	"devuelve la puntuacion que supone tener la pieza dada colocada en el tablero"
	(cond ((or (eq pieza Z5) (eq pieza L5) (eq pieza N5) (eq pieza Y5) (eq pieza U5) (eq pieza V5) 
			   (eq pieza W5) (eq pieza I5) (eq pieza T5) (eq pieza F5) (eq pieza X5) (eq pieza P5)) 5) ;Piezas de 5 bloques.
		  
		  ((or (eq pieza O4) (eq pieza T4) (eq pieza L4) (eq pieza Z4) (eq pieza I4)) 4) 		   	   ;Piezas de 4 bloques.
		  
		  ((or (eq pieza V3) (eq pieza I3)) 3) 													       ;Piezas de 3 bloques.
		  
		  ((eq pieza I2) 2) 																	       ;Pieza de 2 bloques.
		  
		  ((eq pieza I1) 1)) 																	       ;Pieza de 1 bloque.
		  
)	

(defun genera-piezas (piezas-jugador)
	"devuelva una lista con todas las piezas del jugador con sus respectivas rotaciones y reflejos sin repetir ninguna"
	(loop for pieza in piezas-jugador
						  
	  if (equalp pieza (refleja pieza))
													  
		  collect pieza into piezas-movimiento
					
	  else
																
		  append (list pieza (refleja pieza)) into piezas-movimiento
					
						
	if (not (find (rota90 pieza) piezas-movimiento :test #'equalp))
				
		collect (rota90 pieza) into piezas-movimiento
					
	if (not (find (refleja (rota90 pieza)) piezas-movimiento :test #'equalp))
				
		collect (refleja (rota90 pieza)) into piezas-movimiento
					
					
					
	if (not (find (rota180 pieza) piezas-movimiento :test #'equalp))
				
		collect (rota180 pieza) into piezas-movimiento
					
	if (not (find (refleja (rota180 pieza)) piezas-movimiento :test #'equalp))
				
		collect (refleja (rota180 pieza)) into piezas-movimiento
					
					
					
	if (not (find (rota270 pieza) piezas-movimiento :test #'equalp))
				
		collect (rota270 pieza) into piezas-movimiento
					
	if (not (find (refleja (rota270 pieza)) piezas-movimiento :test #'equalp))
				
		collect (refleja (rota270 pieza)) into piezas-movimiento
						   
	finally (return piezas-movimiento))
	
)

(defun tablero-parcial (jugador numero-movimiento)
	"devuelve la coordenada inicial y la longitud que define un subtablero contenido dentro del tablero del juego, 
		dependiendo del jugador y del numero de movimiento"
	
	;Los subtableros vienen determinados por el caso en el que se usara la pieza de mayor longitud en cuanto a anchura y altura. Considerando por ejemplo,
	; que la pieza I5 tiene unas dimensiones de 5x5 pues puede ser colocada en posiciones vertical u horizontal.
	;
	;Por ejemplo, en el caso del segundo movimiento
	;suponemos que se usa I5, por tanto las posibles posiciones para una nueva pieza como mucho se encontraran en el subtablero que contiene esa pieza
	; mas un bloque adiciona, por tanto se usaria el subtablero de 6x6 que empieza en (1, 1) y termina en (6, 6).
	;
	;En el resto de casos, teniendo en cuenta que en el set de piezas solo existe una de longitud 5 y 4 de 4 (el resto no son necesarias pues a partir
	;	del sexto movimiento se considera el tablero completo), se supone que se usan piezas de longitud 4 para determinar el subtablero.
	
	(let ((ftablero (first dim-tablero)) (ctablero (second dim-tablero))
		  (longitudes (list 6 10 14 18 20))) ;Longitudes de los subtableros.
	
	(case jugador
		(1 (case numero-movimiento 
				(2	(list '(1 1) (first longitudes))) 	;Longitud de la pieza mas grande, 5, mas 1 bloque adicional.
				(3  (list '(1 1) (second longitudes)))	;Longitud de la pieza mas grande mas la siguiente mas grande, que es de 4, mas un bloque adicional.
				(4	(list '(1 1) (third longitudes)))
				(5  (list '(1 1) (fourth longitudes)))
				(6	(list '(1 1) (fifth longitudes))))) ;Llegados a este punto el limite es 20.
		
		(2 (case numero-movimiento 
				(2  (list (list 1 (- ctablero (1- (first longitudes))))  (first longitudes)))
				(3	(list (list 1 (- ctablero (1- (second longitudes)))) (second longitudes)))
				(4	(list (list 1 (- ctablero (1- (third longitudes))))  (third longitudes))) 
				(5	(list (list 1 (- ctablero (1- (fourth longitudes)))) (fourth longitudes)))
				(6	(list (list 1 (- ctablero (1- (fifth longitudes))))  (fifth longitudes)))))
				
		(3 (case numero-movimiento 
				(2  (list (list (- ftablero (1- (first longitudes)))  1) (first longitudes)))
				(3	(list (list (- ftablero (1- (second longitudes))) 1) (second longitudes)))
				(4	(list (list (- ftablero (1- (third longitudes)))  1) (third longitudes))) 
				(5	(list (list (- ftablero (1- (fourth longitudes))) 1) (fourth longitudes)))
				(6	(list (list (- ftablero (1- (fifth longitudes)))  1) (fifth longitudes)))))
				
		(4 (case numero-movimiento 
				(2  (list (list (- ftablero (1- (first longitudes)))  (- ctablero (1- (first longitudes))))  (first longitudes)))
				(3	(list (list (- ftablero (1- (second longitudes))) (- ctablero (1- (second longitudes)))) (second longitudes)))
				(4	(list (list (- ftablero (1- (third longitudes)))  (- ctablero (1- (third longitudes))))  (third longitudes))) 
				(5	(list (list (- ftablero (1- (fourth longitudes))) (- ctablero (1- (fourth longitudes)))) (fourth longitudes)))
				(6	(list (list (- ftablero (1- (fifth longitudes)))  (- ctablero (1- (fifth longitudes))))  (fifth longitudes)))))))
				
)

(defun rota90 (pieza)
	"rota 90 grados la pieza dada"
	(let* ((dim (array-dimensions pieza)) (f (first dim)) (c (second dim)) (res (make-array (list c f))))
		(loop for i from 0 to (- f 1)
			do (loop for j from 0 to (- c 1)
					do (setf (aref res j (- (- f 1) i)) (aref pieza i j))))
	res)
)

(defun rota180 (pieza)
	"rota 180 grados la pieza dada"
	(rota90 (rota90 pieza))
)

(defun rota270 (pieza)
	"rota 270 grados la pieza dada"
	(rota90 (rota90 (rota90 pieza)))
)

(defun refleja (pieza)
	"refleja la forma de la pieza original dada"
	(let* ((dim (array-dimensions pieza)) (f (first dim)) (c (second dim)) (res (make-array (list f c))))
		(loop for i from 0 to (- f 1)
			do (loop for j from 0 to (- c 1)
					do (setf (aref res i (- (- c 1) j)) (aref pieza i j))))
    res)
)

(defun copia-estado (estado-actual)
	"crea una copia del estado dado" ;Para generar estado sucesor sin que se altere el estado actual.
	(let ((copia-estado (make-estado)))
		(setf (estado-tablero copia-estado) (copia-tablero (estado-tablero estado-actual)))
		
		(loop for j from 1 to *numero-jugadores*
			do (setf (gethash j (estado-jugadores copia-estado)) (gethash j (estado-jugadores estado-actual))))
			
		copia-estado)
)
	
(defun copia-tablero (tablero)
	"crea una copia del tablero dado" ;Evita que al modificar el tablero del estado sucesor, no se modifique tambien el del estado actual.
	(let ((copia-tablero (make-array dim-tablero)))
		
		(dotimes (i (array-total-size tablero))
			(setf (row-major-aref copia-tablero i) (row-major-aref tablero i)))
		
		copia-tablero)
)

(defun movimiento-valido (tablero pieza posicion jugador inicial)
	"determina si un movimiento se puede aplicar"
	(let* ((dim-pieza (array-dimensions pieza))
		   (fpieza (first dim-pieza)) (cpieza (second dim-pieza))
		   (tx (- (first posicion) 1)) (ty (- (second posicion) 1))
		   (diagonal nil)	;Indica si existe algun bloque, del mismo jugador, que toque diagonalmente a uno de la pieza.
		   (valido t))		;Indica si el movimiento es valido.
		   
		(if (not inicial)
			(loop for i from 0 to (- fpieza 1) ;Recorre la pieza asociada al movimiento.
				do (loop for j from 0 to (- cpieza 1)
						if (not (eq (aref pieza i j) 0)) ;Si la posicion contiene un 0 no es un bloque de la pieza.
							do (if (fuera-del-tablero (+ i tx) (+ j ty))
								   (progn (setf valido nil) (loop-finish)) ;Bloque fuera del tablero.
								   (if (bloque-solapado tablero (+ i tx) (+ j ty)) 
								       (progn (setf valido nil) (loop-finish)) ;Bloque solapado con uno ya colocado en el tablero.
									   (if (bloque-contiguo tablero (+ i tx) (+ j ty) jugador) 
								           (progn (setf valido nil) (loop-finish)) ;Bloque contiguo a otros del mismo jugador.
								           (if (bloque-diagonal tablero (+ i tx) (+ j ty) jugador)
									           (setf diagonal t)))))) ;Toca diagonalmente otro bloque del mismo jugador.
				if (not valido) do (loop-finish)) ;Sale del bucle.
			
			(if (not (inicial-valido pieza tablero tx ty jugador))
				(setf valido nil)))
				
			
		(if (not valido) ;Hay solapamiento, bloques contiguos pertenecientes al mismo jugador o no es un movimiento inicial valido.
			 nil
			(if (and (not diagonal) (not inicial)) ;No hay bloques diagonales y al no ser inicial invalida el movimiento.
				nil
				t)))
)

(defun inicial-valido (pieza tablero tx ty jugador)
	"determina si el movimiento inicial para el jugador y las coordenadas dadas es valido"
	(let* ((dim-pieza (array-dimensions pieza))
		   (fpieza (first dim-pieza)) (cpieza (second dim-pieza))
		   (pinicial (posicion-inicial pieza jugador)) ;Posicion inicial en el tablero.
		   (pinicialx (1- (first pinicial))) (pinicialy (1- (second pinicial))))
		   
		  (if (and (= tx pinicialx) (= ty pinicialy) 		   ;Los valores de la posicion dada corresponden con la posicion inicial del jugador.
					(eq (aref tablero pinicialx pinicialy) 0)) ;El movimiento inicial no se ha llevado a cabo todavia, la casilla esta vacia.
		   
			  (case jugador (1 (if (not (eq (aref pieza 0 0) 0)) (return-from inicial-valido t)))	;La pieza tiene un bloque para la casilla inicial.
									  
							(2 (if (not (eq (aref pieza 0 (1- cpieza)) 0)) (return-from inicial-valido t)))
	  
							(3 (if (not (eq (aref pieza (1- fpieza) 0) 0)) (return-from inicial-valido t)))
		   
							(4 (if (not (eq (aref pieza (1- fpieza) (1- cpieza)) 0)) (return-from inicial-valido t)))))
							
	nil)
	
)

(defun posicion-inicial (pieza jugador)
	"devuelve la posicion inicial para el jugador dado en funcion de la pieza dada"
	(let* ((dim-pieza (array-dimensions pieza))
		   (fpieza (first dim-pieza)) (cpieza (second dim-pieza))
		   (ftablero (first dim-tablero)) (ctablero (second dim-tablero)))
		   
		   (cond ((= jugador 1) (list 1 1))
				 ((= jugador 2) (list 1 (- ctablero (1- cpieza))))
				 ((= jugador 3) (list (- ftablero (1- fpieza)) 1))
				 ((= jugador 4) (list (- ftablero (1- fpieza)) (- ctablero (1- cpieza))))))
				 
)	

(defun fuera-del-tablero (fila columna)
	"determina si la coordenada dada (fila, columna) se sale del tablero"
	(let* ((ftablero (first dim-tablero)) (ctablero (second dim-tablero)))
		(or (< fila 0) (< columna 0) (>= fila ftablero) (>= columna ctablero)))
)

(defun bloque-solapado (tablero tx ty)
	"determina si el bloque de la pieza se solapa con un bloque ya colocado en el tablero"
	(not (eq (aref tablero tx ty) 0))		 
)

(defun bloque-contiguo (tablero tx ty jugador)
	"determina si la posicion dada tiene algun bloque contiguo ya colocado en el tablero y perteneciente al mismo jugador"
	(let* ((ftablero (first dim-tablero))
		   (ctablero (second dim-tablero))
		   (bsuperior 0) (bderecho 0)
		   (binferior 0) (bizquierdo 0))
		   
		(if (= tx 0) ;Primera fila.
			(if (= ty 0) ;Primera columna.
				(progn (setf bderecho (aref tablero 0 1))	;(0, 0)
					   (setf binferior (aref tablero 1 0))) ;(0, 0)
					   
				(if (= ty (- ctablero 1)) ;Ultima columna.
					(progn (setf bizquierdo (aref tablero 0 (- ty 1)))	;(0, ctablero)
					       (setf binferior (aref tablero 1 ty))) 		;(0, ctablero)
						   
					(progn (setf bderecho (aref tablero 0 (+ ty 1)))	 ;(0, y)
						   (setf binferior (aref tablero 1 ty)) 		 ;(0, y)
						   (setf bizquierdo (aref tablero 0 (- ty 1))))));(0, y)
						   
			(if (= tx (- ftablero 1)) ;Ultima fila.
				(if (= ty 0) ;Primera columna.
					(progn (setf bsuperior (aref tablero (- tx 1) 0)) ;(ftablero, 0)
						   (setf bderecho (aref tablero tx 1)))		  ;(ftablero, 0)
						   
					(if (= ty (- ctablero 1)) ;Ultima columna.
						(progn (setf bsuperior (aref tablero (- tx 1) ty))  ;(ftablero, ctablero)
							   (setf bizquierdo (aref tablero tx (- ty 1))));(ftablero, ctablero)
							   
						(progn (setf bderecho (aref tablero tx (+ ty 1)))	  ;(ftablero, y)
						       (setf bsuperior (aref tablero (- tx 1) ty))    ;(ftablero, y)
						       (setf bizquierdo (aref tablero tx (- ty 1))))));(ftablero, y)
							   
				(if (= ty 0) ;Primera columna.
					(progn (setf bsuperior (aref tablero (- tx 1) 0))  ;(x, 0)
						   (setf bderecho (aref tablero tx 1))		   ;(x, 0)
						   (setf binferior (aref tablero (+ tx 1) 0))) ;(x, 0)
						   
					(if (= ty (- ctablero 1)) ;Ultima columna.
						(progn (setf bsuperior (aref tablero (- tx 1) ty)) ;(x, ctablero)
							   (setf bizquierdo (aref tablero tx (- ty 1)));(x, ctablero)
							   (setf binferior (aref tablero (+ tx 1) ty)));(x, ctablero)
							   
						(progn (setf bsuperior (aref tablero (- tx 1) ty)) 		 ;(x, y)
							   (setf bderecho (aref tablero tx (+ ty 1)))  		 ;(x, y)
							   (setf binferior (aref tablero (+ tx 1) ty)) 		 ;(x, y)
							   (setf bizquierdo (aref tablero tx (- ty 1)))))))) ;(x, y)
						   
						   
					
		(loop for valor in (list bsuperior bderecho binferior bizquierdo)
			if (eq valor jugador) return t))
)

(defun bloque-diagonal(tablero tx ty jugador)
	"determina si la posicion dada tiene algun bloque diagonal ya colocado en el tablero y perteneciente al mismo jugador"
	(let* ((ftablero (first dim-tablero))
		   (ctablero (second dim-tablero))
		   (bsuperior-izq 0) (bsuperior-der 0)
		   (binferior-izq 0) (binferior-der 0))
		   
		(if (= tx 0) ;Primera fila.
			(if (= ty 0) ;Primera columna.
				(setf binferior-der (aref tablero 1 1)) ;(0, 0)
					
				(if (= ty (- ctablero 1)) ;Ultima columna.
					(setf binferior-izq (aref tablero 1 (- ty 1))) ;(0, ctablero)
						
					(progn (setf binferior-der (aref tablero 1 (+ ty 1))) 	;(0, y)
						   (setf binferior-izq (aref tablero 1 (- ty 1))))));(0, y)
							   			   
			(if (= tx (- ftablero 1)) ;Ultima fila.
				(if (= ty 0) ;Primera columna.
					(setf bsuperior-der (aref tablero (- tx 1) 1)) ;(ftablero, 0)
						
					(if (= ty (- ctablero 1)) ;Ultima columna.
						(setf bsuperior-izq (aref tablero (- tx 1) (- ty 1))) ;(ftablero, ctablero)
							
						(progn (setf bsuperior-der (aref tablero (- tx 1) (+ ty 1)))   ;(ftablero, y)
							   (setf bsuperior-izq (aref tablero (- tx 1) (- ty 1))))));(ftablero, y)
								   
				(if (= ty 0); Primera columna.
					(progn (setf bsuperior-der (aref tablero (- tx 1) 1)) ;(x, 0)
						   (setf binferior-der (aref tablero (+ tx 1) 1)));(x, 0)
							   
					(if (= ty (- ctablero 1)) ;Ultima columna.
						(progn (setf bsuperior-izq (aref tablero (- tx 1) (- ty 1))) ;(x, ctablero)
							   (setf binferior-izq (aref tablero (+ tx 1) (- ty 1))));(x, ctablero)
								   
						(progn (setf bsuperior-der (aref tablero (- tx 1) (+ ty 1))) 	  ;(x, y)
							   (setf binferior-der (aref tablero (+ tx 1) (+ ty 1))) 	  ;(x, y)
							   (setf binferior-izq (aref tablero (+ tx 1) (- ty 1))) 	  ;(x, y)
							   (setf bsuperior-izq (aref tablero (- tx 1) (- ty 1)))))))) ;(x, y)
		
		(loop for valor in (list bsuperior-der binferior-der binferior-izq bsuperior-izq)
			if (eq valor jugador) return t))	
)
