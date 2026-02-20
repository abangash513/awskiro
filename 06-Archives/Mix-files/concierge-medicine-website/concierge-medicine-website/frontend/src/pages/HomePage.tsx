import { Container, Typography, Box, Button, Stack } from '@mui/material';

function HomePage(): JSX.Element {
  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 8 }}>
        <Typography variant="h1" component="h1" gutterBottom>
          Concierge Medicine
        </Typography>
        <Typography variant="h5" color="textSecondary" paragraph>
          Personalized healthcare at your fingertips
        </Typography>
        <Stack direction="row" spacing={2} sx={{ mt: 4 }}>
          <Button variant="contained" size="large">
            Learn More
          </Button>
          <Button variant="outlined" size="large">
            Contact Us
          </Button>
        </Stack>
      </Box>
    </Container>
  );
}

export default HomePage;
