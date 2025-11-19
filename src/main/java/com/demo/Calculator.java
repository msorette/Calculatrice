package com.demo;

/**
 * Classe Calculator pour la démo d'intégration Codebeamer.
 * Contient des méthodes simples pour démontrer le cycle de développement et tests.
 */
public class Calculator {

    /**
     * Affiche le message "Hello world".
     *
     * @return Le message "Hello world"
     */
    public String sayHello() {
        return "Hello - world";
    }

    /**
     * Additionne deux nombres.
     *
     * @param a Premier nombre
     * @param b Deuxième nombre
     * @return La somme de a et b
     */
    public int add(int a, int b) {
        return a + b;
    }

    /**
     * Divise deux nombres.
     *
     * @param a Le dividende
     * @param b Le diviseur
     * @return Le résultat de la division a / b
     * @throws ArithmeticException Si b est égal à 0
     */
    public double divide(double a, double b) {
        if (b == 0) {
            throw new ArithmeticException("Division par zéro impossible");
        }
        return a / b;
    }
}
