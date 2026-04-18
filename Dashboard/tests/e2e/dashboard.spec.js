import { test, expect } from '@playwright/test';

test.describe('Maintenance Suite Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // We assume the development server is running during tests
    await page.goto('/');
  });

  test('1. should have the correct title and header', async ({ page }) => {
    await expect(page).toHaveTitle(/Maintenance Suite Dashboard/);
    await expect(page.locator('h1')).toContainText('Maintenance Suite');
  });

  test('2. should show system online status badge', async ({ page }) => {
    const status = page.locator('#service-status');
    await expect(status).toBeVisible();
    await expect(status).toContainText('Systém je online');
  });

  test('3. should display storage analytics components', async ({ page }) => {
    await expect(page.locator('.stats-card')).toBeVisible();
    await expect(page.locator('#storage-used-bar')).toBeVisible();
    await expect(page.locator('#storage-used-val')).toBeVisible();
  });

  test('4. should have primary and secondary action buttons enabled', async ({ page }) => {
    await expect(page.locator('#btn-full-clean')).toBeEnabled();
    await expect(page.locator('#card-npm button')).toBeEnabled();
    await expect(page.locator('#card-pnpm button')).toBeEnabled();
  });

  test('5. should log activity to terminal when a clean button is clicked', async ({ page }) => {
    const fullCleanBtn = page.locator('#btn-full-clean');
    const terminal = page.locator('#terminal');
    
    await fullCleanBtn.click();
    
    // Check if terminal contains the expected start message
    await expect(terminal).toContainText('Iniciujem čistenie: FULL');
  });

  test('6. should render the history breakdown table', async ({ page }) => {
    const table = page.locator('#history-table');
    await expect(table).toBeVisible();
    await expect(table.locator('thead')).toContainText('Category');
  });

  test('7. should clear the terminal when Clear button is clicked', async ({ page }) => {
    const terminal = page.locator('#terminal');
    const clearBtn = page.locator('.clear-btn');
    
    // First, ensure there is something in the terminal (default welcome message is there)
    await expect(terminal).not.toBeEmpty();
    
    await clearBtn.click();
    
    // Check for the "Console cleared..." message which indicates it was cleared
    await expect(terminal).toContainText('Console cleared...');
    // And it should no longer contain the welcome message if cleared properly
    await expect(terminal).not.toContainText('Vitajte v Maintenance Suite');
  });
});
