public class RandomNumberGenerator {
    //Takes an Integer input and throws an exception if the Integer is not positive 
    public static String generateRandomNumber(Integer digits) {
        if (digits <= 0) {
        throw new IllegalArgumentException('Number of digits must be positive');
        }
        
        //This part creates the random number based on the 'digits' argument
        Long randomLong = Math.abs(Crypto.getRandomLong());
        Long maxValue = (Long)Math.pow(10, digits) - (Long)Math.pow(10, digits - 1);
        Long baseValue = (Long)Math.pow(10, digits - 1);
        Long randomNumber = Math.mod(randomLong, maxValue) + baseValue;
    
        return String.valueOf(randomNumber);
    }
}