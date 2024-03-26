
*INCLUDE bib_aux.s

* Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           * Pila
        DC.L    INICIO          * PC
        *DC.L    BERROR_RTE

        ORG     $400

* Definicion de equivalencias
*********************************

MR1A    EQU     $effc01       * de modo A (escritura)
MR2A    EQU     $effc01       * de modo A (segunda escritura)
SRA     EQU     $effc03       * de estado A (lectura)
CSRA    EQU     $effc03       * de seleccion de reloj A (escritura)
CRA     EQU     $effc05       * de control A (escritura)
TBA     EQU     $effc07       * buffer transmision A (escritura)
RBA     EQU     $effc07       * buffer recepcion A  (lectura)
ACR     EQU     $effc09       * de control auxiliar
IMR     EQU     $effc0B       * de mascara de interrupcion A (escritura)
ISR     EQU     $effc0B       * de estado de interrupcion A (lectura)
MR1B    EQU     $effc11       * de modo B (escritura)
MR2B    EQU     $effc11       * de modo B (segunda escritura)
CRB     EQU     $effc15       * de control A (escritura)
TBB     EQU     $effc17       * buffer transmision B (escritura)
RBB     EQU     $effc17       * buffer recepcion B (lectura)
SRB     EQU     $effc13       * de estado B (lectura)
CSRB    EQU     $effc13       * de seleccion de reloj B (escritura)
IVR		EQU		$effc19	      * del vector de interrupcion

CR      EQU     $0D           * Carriage Return
LF      EQU     $0A           * Line Feed
FLAGT   EQU     2             * Flag de transmision
FLAGR   EQU     0             * Flag de recepcion
PIMR	DC.W	0     	      * Variable para guardar IMR


********************* INIT *****************************
INIT:
	
	MOVE.B      #%00010000,CRA      * Reinicia el puntero MR1A
    MOVE.B      #%00000011,MR1A     * 8 bits por caracter.
    MOVE.B      #%00000000,MR2A     * Eco desactivado.
    MOVE.B      #%11001100,CSRA     * Velocidad = 38400 bps.
    MOVE.B      #%00000000,ACR      * Conjunto 1
    MOVE.B      #%00000101,CRA      * Habilita transmision y recepcion 

	MOVE.B		#%00010000,CRB	    * Reinicia el puntero MR1B
	MOVE.B		#%00000011,MR1B	    * 8 bits por caracter
	MOVE.B		#%00000000,MR2B	    * Eco desactivado
	MOVE.B		#%11001100,CSRB	    * Velocidad = 38400 bps
	MOVE.B		#%00000101,CRB	    * Habilita transmision y recepcion
	MOVE.B		#$40,IVR	    	* Registro de vector
    MOVE.L      #RTI,$100	    	* Poner dir(RTI) en el VecInt
	MOVE.B		#%00100010,IMR	    * Habilitar interrupciones de recepcion
	MOVE.B		#%00100010,PIMR	    * Guardo en la variable la IMR
	BSR INI_BUFS			    	* Inicializar los buffers
	RTS
****************** FIN INIT ****************************

****************** PRINT ******************************
PRINT:
	MOVE.L 4(A7),A1		* dir Buffer
	EOR.L D2,D2
	MOVE.W 8(A7),D2		* Descriptor
	EOR.L D3,D3
	MOVE.W 10(A7),D3	* Tamaño
	MOVE.L #2,D1	 	* Mascara de interrupcion

	MOVE.L #-1,D0
	CMP.L #2,D2
	BGE FIN_PRINT		* Mal paso de parametros
	EOR.L D0,D0
	CMP.L #0,D2
	BEQ BUC_PRINT
	MULS #8,D1			* Ajustar la mascara de interrupcion
BUC_PRINT:
	CMP.L D0,D3
	BEQ FIN_PRINT		* Se ha completado el buffer
	MOVEM.L D0-D1/A1,-(A7) * Salvaguarda de parametros
	MOVE.L D2,D0
	EOR.L D1,D1
	MOVE.B (A1)+,D1
	BSR ESCCAR
	MOVE.L D0,D2
	MOVEM.L (A7)+,D0-D1/A1
	CMP.L #-1,D2
	BEQ FIN_PRINT		* Ya no hay mas caracteres en el BuffIntierno
	ADD.L #1,D0
	EOR.L D2,D2			* Recuperacion de los parametros
	MOVE.W 8(A7),D2		* Descriptor
	EOR.L D3,D3
	MOVE.W 10(A7),D3	* Tamaño
	MOVE.B PIMR,D4
	AND.B D4,D1
	BNE BUC_PRINT		* comprobar si esta habilitada la transmision
	OR.B D1,PIMR
	MOVE.B PIMR,IMR		* Havilitar las int de transmision de la linea
	BRA BUC_PRINT
FIN_PRINT:
	RTS
***************** FIN PRINT **************************

******************** SCAN *****************************
SCAN:
	MOVE.L 4(A7),A1		* dir Buffer
	EOR.L D2,D2
	MOVE.W 8(A7),D2		* Descriptor
	EOR.L D1,D1
	MOVE.W 10(A7),D1	* Tamaño
	
	MOVE.L #-1,D0
	CMP.L #2,D2
	BGE FIN_SCAN		* Mal paso de parametros
	EOR.L D0,D0
BUC_SCAN:
	CMP.L D0,D1
	BEQ FIN_SCAN		* Se ha completado el buffer
	MOVEM.L D0/A1,-(A7) * Salvaguarda de parametros
	MOVE.L D2,D0
	BSR LEECAR
	MOVE.L D0,D2
	MOVEM.L (A7)+,D0/A1
	CMP.L #-1,D2
	BEQ FIN_SCAN		* Ya no hay mas caracteres en el BuffInt

	MOVE.B D2,(A1)+
	ADD.L #1,D0
	EOR.L D2,D2			* Recuperacion de los parametros
	MOVE.W 8(A7),D2		* Descriptor
	EOR.L D1,D1
	MOVE.W 10(A7),D1	* Tamaño
	BRA BUC_SCAN
FIN_SCAN:
	RTS
******************* FIN SCAN **************************

******************** RTI *******************************
RTI:
	MOVEM.L D0-D1/A1,-(A7)		* Salvaguada de registros
	MOVE.L #2,D0
	MOVE.L #TBA,A1
	MOVE.B #%11111110,D1
	BTST #3,SRA			* Transmision de A
	BEQ TRANS_RTI
	MOVE.L #RBA,A1
	BTST #0,SRA			* Recepcion de A
	BEQ REC_RTI
	MOVE.L #3,D0
	MOVE.L #TBB,A1
	MOVE.B #%11110111,D1
	BTST #3,SRB			* Transmision de B
	BEQ TRANS_RTI
	MOVE.L #RBB,A1
	BTST #0,SRB			* Recepcion de B
	BEQ REC_RTI

TRANS_RTI:
	BSR LEECAR
	CMP.L #-1,D0
	BEQ SLT1
	MOVE.B D0,(A1)
	BRA FIN_RTI
SLT1:
	AND.B D1,PIMR
	MOVE.B PIMR,IMR
	BRA FIN_RTI
REC_RTI:
	EOR.L D1,D1
	MOVE.B (A1),D1
	BSR ESCCAR
FIN_RTI:
	MOVEM.L (A7)+,D0-D1/A1 *Recuperacion de registros
    RTE
******************* FIN RTI ***************************

******************* INICIO ****************************
	BUFFER: DS.B 2100 * Buffer para lectura y escritura de caracteres
	PARDIR: DC.L 0	* Dirección que se pasa como parámetro
	PARTAM: DC.W 0	* Tamaño que se pasa como parámetro
	CONTC: DC.W  0	* Contador de caracteres a imprimir
	DESA: EQU	 0	* Descriptor lı́nea A	
	DESB: EQU	 1	* Descriptor lı́nea B
	TAMBS: EQU	 30	* Tamaño de bloque para SCAN
	TAMBP: EQU	 7	* Tamaño de bloque para PRINT
					* Manejadores de excepciones
INICIO: 
	MOVE.L #BUS_ERROR,8 * Bus error handler
	MOVE.L #ADDRESS_ER,12 * Address error handler
	MOVE.L #ILLEGAL_IN,16 * Illegal instruction handler
	MOVE.L #PRIV_VIOLT,32 * Privilege violation handler
	MOVE.L #ILLEGAL_IN,40 * Illegal instruction handler
	MOVE.L #ILLEGAL_IN,44 * Illegal instruction handler

	BSR	INIT * Llama a INIT
	MOVE.W #$2000,SR * Permite interrupciones
BUCPR:
	MOVE.W #TAMBS,PARTAM
	MOVE.L #BUFFER,PARDIR
OTRAL:
	MOVE.W PARTAM,-(A7) * Tamaño de bloque
	MOVE.W #DESA,-(A7) * Puerto A
	MOVE.L PARDIR,-(A7) * Dirección de lectura
ESPL:
	BSR SCAN
	ADD.L #8,A7 * Reestablece la pila
	ADD.L D0,PARDIR * Calcula la nueva dirección de lectura
	SUB.W D0,PARTAM * Actualiza el número de caracteres leı́dos
	BNE	  OTRAL * Si no se han leı́do todas los caracteres
				* Vuelve a leer
	MOVE.W #TAMBS,CONTC * Inicializa contador de caracteres a imprimir
	MOVE.L #BUFFER,PARDIR * Parámetro BUFFER = comienzo del buffer
OTRAE: 
	MOVE.W #TAMBP,PARTAM * Tamaño de escritura = Tamaño de bloque
ESPE:
	MOVE.W PARTAM,-(A7) * Tamaño de escritura
	MOVE.W #DESB,-(A7) * Puerto B
	MOVE.L PARDIR,-(A7) * Dirección de escritura
	BSR PRINT 
	ADD.L #8,A7 * Restablece la pila
	ADD.L D0,PARDIR * Calcula la nueva dirección del buffer
	SUB.W D0,CONTC * Actualiza el contador de caracteres
	BEQ SALIR * Si no quedan caracteres se acaba
	SUB.W D0,PARTAM * Actualiza el tamaño de escritura
	BNE ESPE * Si no se ha escrito todo el bloque se insiste
	CMP.W #TAMBP,CONTC 	* Si el no de caracteres que quedan es menor que
						* el tamaño establecido se imprime ese número

	BHI OTRAE * Siguiente bloque
	MOVE.W CONTC,PARTAM 
	BRA ESPE * Siguiente bloque

SALIR:
	BRA BUCPR 

BUS_ERROR: * Bus error handler
	BREAK 
	NOP

ADDRESS_ER: * Address error handler
	BREAK 
	NOP

ILLEGAL_IN: * Illegal instruction handler
	BREAK 
	NOP

PRIV_VIOLT: * Privilege violation handler
	BREAK 
	NOP
	BREAK
******************FIN INICIO***************************
