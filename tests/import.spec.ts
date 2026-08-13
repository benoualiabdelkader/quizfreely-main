import { test, expect } from '@playwright/test';

test.describe('Import Terms functionality', () => {
    
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await expect(page.getByRole('banner')).toContainText('Sign in');
        await page.locator('main').last().getByRole('link', { name: 'Sign up' }).click();
        await expect(page.locator('body')).toContainText('Sign Up');
        await page.getByRole('button', { name: 'Continue without an account' }).last().click();
        await expect(page.locator('body')).toContainText('Select "New Studyset" to enter or import terms');
        
        // Go to Create Studyset page
        await page.getByRole('button', { name: 'New Studyset' }).last().click();
        await page.getByRole('textbox', { name: 'Title' }).click();
        await page.getByRole('textbox', { name: 'Title' }).fill('Import Test Set');
        
        // Open Import Modal
        await page.getByRole('button', { name: 'Import terms' }).click();
    });

    test('valid Sentence Unscramble import', async ({ page }) => {
        // Select Unscramble mode
        await page.getByRole('button', { name: 'Sentence Unscramble' }).click();
        
        // Ensure the correct placeholder is shown
        const textarea = page.locator('.import-terms-paste-textarea');
        await expect(textarea).toHaveAttribute('placeholder', 'went / yesterday / to / the / park / we\twe went to the park yesterday');
        
        // Type valid data
        await textarea.fill('went / yesterday / to / the / park / we\twe went to the park yesterday\nbrightly / shone / sky / in / the / sun / the\tthe sun shone brightly in the sky');
        
        // Click import
        await page.getByRole('button', { name: 'Import', exact: true }).click();
        
        // Verify terms are populated correctly
        await expect(page.getByRole('textbox', { name: 'Term' }).first()).toHaveValue('[UNSCRAMBLE]\nwent / yesterday / to / the / park / we');
        await expect(page.getByRole('textbox', { name: 'Definition' }).first()).toHaveValue('we went to the park yesterday');
        
        await expect(page.getByRole('textbox', { name: 'Term' }).nth(1)).toHaveValue('[UNSCRAMBLE]\nbrightly / shone / sky / in / the / sun / the');
        await expect(page.getByRole('textbox', { name: 'Definition' }).nth(1)).toHaveValue('the sun shone brightly in the sky');
    });

    test('malformed rows and empty values in Sentence Unscramble trigger validation', async ({ page }) => {
        // Handle the expected alert
        let dialogMessage = '';
        page.on('dialog', async dialog => {
            dialogMessage = dialog.message();
            await dialog.accept();
        });
        
        await page.getByRole('button', { name: 'Sentence Unscramble' }).click();
        
        const textarea = page.locator('.import-terms-paste-textarea');
        
        // Missing definition column (malformed)
        await textarea.fill('went / yesterday / to / the / park / we\n');
        
        await page.getByRole('button', { name: 'Import', exact: true }).click();
        
        // Verify alert was shown and import did not happen
        expect(dialogMessage).toContain('Import failed: One or more rows are malformed');
        // The modal should remain open because import halted
        await expect(page.getByRole('button', { name: 'Sentence Unscramble' })).toBeVisible();
    });

    test('existing generic imports remain functional', async ({ page }) => {
        await page.getByRole('button', { name: 'Terms & Definitions' }).click();
        
        const textarea = page.locator('.import-terms-paste-textarea');
        await textarea.fill('Apple\tA fruit\nCar\tA vehicle');
        
        await page.getByRole('button', { name: 'Import', exact: true }).click();
        
        await expect(page.getByRole('textbox', { name: 'Term' }).first()).toHaveValue('Apple');
        await expect(page.getByRole('textbox', { name: 'Definition' }).first()).toHaveValue('A fruit');
        await expect(page.getByRole('textbox', { name: 'Term' }).nth(1)).toHaveValue('Car');
        await expect(page.getByRole('textbox', { name: 'Definition' }).nth(1)).toHaveValue('A vehicle');
    });
});
